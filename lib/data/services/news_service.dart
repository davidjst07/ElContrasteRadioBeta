import 'dart:convert';
import 'package:elcontrasteapp/data/models/post_model.dart';
import 'package:http/http.dart' as http;

class NewsService {
  static final NewsService _instance = NewsService._internal();

  factory NewsService() {
    return _instance;
  }

  NewsService._internal();

  static const String _baseUrl =
      'https://elcontraste.co/wp-json/wp/v2/posts?_embed';

  Future<List<Post>> fetchPosts({int? categoryId}) async {
    try {
      var url = _baseUrl;
      if (categoryId != null) {
        url += '&categories=$categoryId';
      }
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Post.fromJson(json)).toList();
      } else {
        throw Exception(
          'Falló al cargar los posts (código: ${response.statusCode})',
        );
      }
    } catch (e) {
      throw Exception('Falló al conectar con el servidor: $e');
    }
  }

  Future<Post> fetchPostById(int id) async {
    final response = await http.get(
      Uri.parse('https://elcontraste.co/wp-json/wp/v2/posts/$id?_embed'),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return Post.fromJson(json);
    } else {
      throw Exception('Error cargando post');
    }
  }
}
