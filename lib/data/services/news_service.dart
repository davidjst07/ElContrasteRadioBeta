import 'dart:convert';

import 'package:elcontrasteapp/data/models/post_model.dart';
import 'package:http/http.dart' as http;

class NewsService {
  static const _baseUrl = 'https://elcontraste.co/wp-json/wp/v2/posts?_embed';

  Future<List<Post>> fetchPosts({int? categoryId}) async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Post.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load posts');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}

// Add your methods and properties here
