import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

/// Genera y persiste un identificador anónimo único por dispositivo.
///
/// No identifica a la persona ni requiere login — se usa únicamente para
/// que el backend pueda limitar a 1 like por dispositivo por reel, y
/// evitar que el contador se infle con toques repetidos.
class DeviceIdStore {
  static const String _boxName = 'device_id_box';
  static const String _key = 'device_id';

  Future<Box<String>>? _boxFuture;

  Future<Box<String>> _getBox() {
    return _boxFuture ??= Hive.openBox<String>(_boxName);
  }

  /// Devuelve el id del dispositivo, generándolo la primera vez.
  Future<String> getDeviceId() async {
    final box = await _getBox();
    final existing = box.get(_key);
    if (existing != null) return existing;

    final newId = const Uuid().v4();
    await box.put(_key, newId);
    return newId;
  }
}
