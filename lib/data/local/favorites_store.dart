import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:elcontrasteapp/data/models/post_model.dart';

/// Guarda noticias marcadas como favoritas — mismo patrón que
/// `NewsCacheStore`: `Box<String>` perezoso, JSON manual, sin adapters.
class FavoritesStore {
  static const String _boxName = 'favorites_box';

  Future<Box<String>>? _boxFuture;

  Future<Box<String>> _getBox() {
    return _boxFuture ??= Hive.openBox<String>(_boxName);
  }

  String _keyFor(int postId) => postId.toString();

  Future<Box<String>> get box => _getBox();

  Future<bool> isFavorite(int postId) async {
    final box = await _getBox();
    return box.containsKey(_keyFor(postId));
  }

  Future<void> toggle(Post post) async {
    final box = await _getBox();
    final key = _keyFor(post.id);
    if (box.containsKey(key)) {
      await box.delete(key);
    } else {
      await box.put(key, jsonEncode(post.toJson()));
    }
  }

  Future<List<Post>> getAll() async {
    final box = await _getBox();
    final posts = <Post>[];
    for (final raw in box.values) {
      try {
        posts.add(Post.fromCacheJson(jsonDecode(raw) as Map<String, dynamic>));
      } catch (e) {
        debugPrint('FavoritesStore: entrada corrupta, se ignora: $e');
      }
    }
    posts.sort((a, b) => b.date.compareTo(a.date));
    return posts;
  }
}
