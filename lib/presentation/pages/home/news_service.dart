import 'dart:convert';
import 'package:elcontrasteapp/presentation/pages/home/post_model.dart';
import 'package:http/http.dart' as http;


class NewsService {
  // La URL de la API REST de tu WordPress.
  // El parámetro `_embed` es clave para que nos incluya datos adicionales como la imagen destacada.
  static const String _baseUrl =
      'https://elcontraste.co/wp-json/wp/v2/posts?_embed';

  Future<List<Post>> fetchPosts() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));

      if (response.statusCode == 200) {
        // Si la respuesta es exitosa, decodificamos el JSON.
        final List<dynamic> data = json.decode(response.body);
        // Convertimos cada item del JSON en un objeto Post.
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
}
