import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:elcontrasteapp/data/models/post_model.dart';

/// Guarda solo la última página 1 exitosa por categoría (stale-while-revalidate).
/// No es un caché completo de paginación.
class NewsCacheStore {
  static const String _boxName = 'news_cache_box';

  Future<Box<String>>? _boxFuture;

  Future<Box<String>> _getBox() {
    return _boxFuture ??= Hive.openBox<String>(_boxName);
  }

  String _keyFor(int? categoryId) => 'category_${categoryId ?? "all"}';

  Future<List<Post>?> read(int? categoryId) async {
    try {
      final box = await _getBox();
      final raw = box.get(_keyFor(categoryId));
      if (raw == null) return null;
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => Post.fromCacheJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('NewsCacheStore: caché corrupto, se ignora: $e');
      return null;
    }
  }

  Future<void> write(int? categoryId, List<Post> posts) async {
    try {
      final box = await _getBox();
      final encoded = jsonEncode(posts.map((p) => p.toJson()).toList());
      await box.put(_keyFor(categoryId), encoded);
    } catch (e) {
      debugPrint('NewsCacheStore: fallo al guardar (no crítico): $e');
    }
  }
}
