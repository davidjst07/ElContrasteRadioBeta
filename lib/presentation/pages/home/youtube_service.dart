import 'dart:convert';
import 'package:elcontrasteapp/presentation/pages/home/video_model.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class YoutubeService {
  // Leemos las claves de forma segura desde las variables de entorno
  final String _apiKey = dotenv.env['YOUTUBE_API_KEY'] ?? 'NO_KEY';
  final String _channelId = dotenv.env['YOUTUBE_CHANNEL_ID'] ?? 'NO_CHANNEL';

  static const String _baseUrl = 'https://www.googleapis.com/youtube/v3/search';

  Future<List<Video>> fetchChannelVideos() async {
    final url = Uri.parse(
      '$_baseUrl?part=snippet&channelId=$_channelId&maxResults=20&order=date&type=video&key=$_apiKey',
    );

    debugPrint('Haciendo petición a YouTube API: $url');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['items'] != null) {
          final List<dynamic> videoList = data['items'];
          return videoList.map((json) => Video.fromJson(json)).toList();
        } else {
          if (data['error'] != null) {
            throw Exception(
              'Error de la API de YouTube: ${data['error']['message']}',
            );
          }
          debugPrint(
              'La API de YouTube no devolvió items, pero tampoco un error. Respuesta: ${response.body}');
          return [];
        }
      } else {
        debugPrint(
            'Error en la respuesta de YouTube API. Código: ${response.statusCode}, Cuerpo: ${response.body}');
        throw Exception(
          'Falló al cargar los videos (código: ${response.statusCode})',
        );
      }
    } catch (e) {
      debugPrint('Excepción al llamar a YouTube API: $e');
      throw Exception('Falló al conectar con el servidor de YouTube: $e');
    }
  }
}
