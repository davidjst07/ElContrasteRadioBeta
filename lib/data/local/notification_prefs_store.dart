import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

/// Guarda qué topics de categoría (`categoria_<id>`) activó el usuario para
/// notificaciones segmentadas — mismo patrón que `NewsCacheStore`. El topic
/// general `todas_las_notas` no vive acá: se suscribe siempre, sin opción.
class NotificationPrefsStore {
  static const String _boxName = 'notification_prefs_box';
  static const String _key = 'subscribed_category_ids';

  Future<Box<String>>? _boxFuture;

  Future<Box<String>> _getBox() {
    return _boxFuture ??= Hive.openBox<String>(_boxName);
  }

  Future<Set<int>> getSubscribedCategoryIds() async {
    try {
      final box = await _getBox();
      final raw = box.get(_key);
      if (raw == null) return {};
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((e) => e as int).toSet();
    } catch (e) {
      debugPrint('NotificationPrefsStore: lectura corrupta, se ignora: $e');
      return {};
    }
  }

  Future<void> setSubscribed(int categoryId, bool subscribed) async {
    final current = await getSubscribedCategoryIds();
    if (subscribed) {
      current.add(categoryId);
    } else {
      current.remove(categoryId);
    }
    final box = await _getBox();
    await box.put(_key, jsonEncode(current.toList()));
  }
}
