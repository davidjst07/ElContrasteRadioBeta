import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:elcontrasteapp/data/models/now_playing_model.dart';
import 'package:elcontrasteapp/data/models/playlist_song_model.dart';

class AzuraCastService {
  static const String streamUrl = 'https://radio.elcontraste.co/listen/el_contraste_radio/radio.mp3';
}

class NowPlayingRepository {
  // CORREGIDO: URL específica de la estación (shortcode)
  static const String _baseUrl = 'https://radio.elcontraste.co/api/nowplaying/el_contraste_radio';

  static Future<NowPlaying?> getNowPlaying() async {
    try {
      final response = await http
          .get(
            Uri.parse(_baseUrl),
            headers: {
              'Accept': 'application/json',
              'User-Agent': 'ElContrasteRadioApp/1.0',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final dynamic json = jsonDecode(response.body);

        // Maneja tanto objeto directo como array
        final Map<String, dynamic> stationData = (json is List && json.isNotEmpty)
            ? json.first as Map<String, dynamic>
            : json as Map<String, dynamic>;

        return NowPlaying.fromJson(stationData);
      } else {
        debugPrint('Error: Código de estado ${response.statusCode}');
        return null;
      }
    } on TimeoutException catch (_) {
      debugPrint('Timeout al conectar con la API');
      return null;
    } catch (e) {
      debugPrint('Error obteniendo now playing: $e');
      return null;
    }
  }

  // Cola de próximas canciones (opcional, corregido)
  static Future<List<PlaylistSong>> getUpcomingSongs() async {
    try {
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'ElContrasteRadioApp/1.0',
        },
      );
      if (response.statusCode == 200) {
        final dynamic json = jsonDecode(response.body);
        final Map<String, dynamic> stationData = (json is List && json.isNotEmpty)
            ? json.first as Map<String, dynamic>
            : json as Map<String, dynamic>;

        final List<dynamic> history = stationData['song_history'] ?? [];
        return history.take(5).map((song) => PlaylistSong.fromJson(song)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error obteniendo cola: $e');
      return [];
    }
  }
}
