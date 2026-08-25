import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:elcontrasteapp/data/local/device_id_store.dart';
import 'package:elcontrasteapp/data/services/reels_service.dart';

/// Guarda localmente qué reels le dio "like" el usuario, y sincroniza
/// ese estado con el backend en segundo plano (mejor esfuerzo).
///
/// El estado local en Hive es la fuente de verdad para la UI — persiste
/// entre sesiones y funciona incluso si el backend todavía no tiene el
/// endpoint de likes o no hay conexión. La sincronización con el
/// servidor (contador compartido) es un plus que no bloquea ni rompe
/// nada si falla.
class LikedReelsStore {
  static const String _boxName = 'liked_reels_box';

  final ReelsService _reelsService;
  final DeviceIdStore _deviceIdStore;

  LikedReelsStore({ReelsService? reelsService, DeviceIdStore? deviceIdStore})
    : _reelsService = reelsService ?? GetIt.I<ReelsService>(),
      _deviceIdStore = deviceIdStore ?? GetIt.I<DeviceIdStore>();

  Future<Box<bool>>? _boxFuture;

  Future<Box<bool>> _getBox() {
    return _boxFuture ??= Hive.openBox<bool>(_boxName);
  }

  Future<Box<bool>> get box => _getBox();

  Future<bool> isLiked(String reelId) async {
    final box = await _getBox();
    return box.containsKey(reelId);
  }

  /// Marca el reel como "gustado". Se usa en el doble-tap: al estilo
  /// Instagram/TikTok, doble-tap solo AGREGA el like, nunca lo quita.
  Future<void> like(String reelId) async {
    final box = await _getBox();
    if (box.containsKey(reelId)) return; // Ya tenía like, no repetir sync
    await box.put(reelId, true);
    _syncWithBackend(reelId, liked: true);
  }

  /// Alterna el like. Se usa en el botón de corazón explícito.
  Future<void> toggle(String reelId) async {
    final box = await _getBox();
    final willBeLiked = !box.containsKey(reelId);
    if (willBeLiked) {
      await box.put(reelId, true);
    } else {
      await box.delete(reelId);
    }
    _syncWithBackend(reelId, liked: willBeLiked);
  }

  /// Sincroniza con el backend sin bloquear la UI. Silencioso a
  /// propósito: el estado local ya quedó guardado sin importar si esto
  /// falla (backend sin endpoint todavía, sin conexión, etc.)
  void _syncWithBackend(String reelId, {required bool liked}) async {
    try {
      final deviceId = await _deviceIdStore.getDeviceId();
      if (liked) {
        await _reelsService.likeReel(reelId, deviceId);
      } else {
        await _reelsService.unlikeReel(reelId, deviceId);
      }
    } catch (_) {
      // Ya se logueó dentro de ReelsService; nada más que hacer aquí.
    }
  }
}
