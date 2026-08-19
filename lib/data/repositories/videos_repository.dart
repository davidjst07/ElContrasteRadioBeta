import 'dart:convert';
import 'package:elcontrasteapp/data/models/video_model.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class VideosRepository {
  // Proxy propio (Cloud Function) — la API key de YouTube vive en el
  // servidor, nunca en el bundle de la app.
  static const String _proxyUrl =
      'https://us-central1-elcontrastenoticias-f0ac1.cloudfunctions.net/youtubeVideos';
  static const String _liveStatusUrl =
      'https://us-central1-elcontrastenoticias-f0ac1.cloudfunctions.net/youtubeLiveStatus';

  Future<Video?> fetchLiveVideo() async {
    final url = Uri.parse(_liveStatusUrl);

    try {
      final response = await http.get(url);
      if (response.statusCode != 200) {
        debugPrint(
          'Error revisando estado en vivo. Código: ${response.statusCode}',
        );
        return null;
      }

      final data = json.decode(response.body);
      if (data['live'] == true && data['video'] != null) {
        return Video.fromJson(data['video']);
      }
      return null;
    } catch (e) {
      debugPrint('Excepción al revisar estado en vivo: $e');
      return null;
    }
  }

  Future<List<Video>> fetchChannelVideos() async {
    final url = Uri.parse(_proxyUrl);

    debugPrint('Haciendo petición al proxy de videos: $url');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['items'] != null) {
          final List<dynamic> videoList = data['items'];
          return videoList.map((json) => Video.fromJson(json)).toList();
        } else {
          if (data['error'] != null) {
            throw Exception('Error del proxy de videos: ${data['error']}');
          }
          debugPrint(
            'El proxy no devolvió items, pero tampoco un error. Respuesta: ${response.body}',
          );
          return [];
        }
      } else {
        debugPrint(
          'Error en la respuesta del proxy. Código: ${response.statusCode}, Cuerpo: ${response.body}',
        );
        throw Exception(
          'Falló al cargar los videos (código: ${response.statusCode})',
        );
      }
    } catch (e) {
      debugPrint('Excepción al llamar al proxy de videos: $e');
      throw Exception('Falló al conectar con el servidor de videos: $e');
    }
  }
}
