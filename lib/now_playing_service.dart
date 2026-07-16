import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class AzuraCastService {
  static const String streamUrl = 'https://radio.elcontraste.co/listen/el_contraste_radio/radio.mp3';
}

class NowPlayingService {
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

class NowPlaying {
  final String title;
  final String artist;
  final String? album;
  final int listeners;
  final int uniqueListeners;
  final String playlistName;
  final int elapsedSeconds;
  final int durationSeconds;
  final String? albumArtUrl;
  final bool isLive;
  final String? streamerName;

  NowPlaying({
    required this.title,
    required this.artist,
    this.album,
    required this.listeners,
    required this.uniqueListeners,
    required this.playlistName,
    required this.elapsedSeconds,
    required this.durationSeconds,
    this.albumArtUrl,
    required this.isLive,
    this.streamerName,
  });

  factory NowPlaying.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> nowPlaying = json['now_playing'] ?? {};
    final Map<String, dynamic> song = nowPlaying['song'] ?? {};
    
    // CORREGIDO: Prioriza 'text' (nombre completo), luego combina title/artist
    String fullTitle = (song['text'] as String?)?.trim() ?? '';
    String artist = (song['artist'] as String?)?.trim().isNotEmpty == true 
        ? song['artist'] 
        : '';
    String title = (song['title'] as String?)?.trim() ?? fullTitle;

    if (artist.isEmpty && fullTitle.isNotEmpty) {
      // Si no hay artist separado, usa solo title
      artist = '';
    }

    final Map<String, dynamic>? links = song['links'];
    final int listeners = (json['listeners']?['current'] as int?) ?? 0;
    final int uniqueListeners = (json['listeners']?['unique'] as int?) ?? 0;
    final String playlistName = (nowPlaying['playlist'] as String?) ?? 'AutoDJ';
    final int elapsed = (nowPlaying['elapsed'] as int?) ?? 0;
    final int duration = (nowPlaying['duration'] as int?) ?? 0;
    final String? albumArt = (links?['art'] as String?) ?? 
        (song['art'] as String?);

    final bool isLive = (json['live']?['is_live'] as bool?) ?? false;
    final String? streamerName = (json['live']?['streamer_name'] as String?);

    return NowPlaying(
      title: title.isEmpty ? 'Cargando...' : title,
      artist: artist.isEmpty ? '' : artist,
      album: song['album'] as String?,
      listeners: listeners,
      uniqueListeners: uniqueListeners,
      playlistName: playlistName,
      elapsedSeconds: elapsed,
      durationSeconds: duration,
      albumArtUrl: albumArt,
      isLive: isLive,
      streamerName: streamerName,
    );
  }

  // ... mantén tus métodos getProgress(), getRemainingTime(), etc. igual ...
  double getProgress() {
    if (durationSeconds == 0) return 0.0;
    return (elapsedSeconds / durationSeconds).clamp(0.0, 1.0);
  }

  String getRemainingTime() {
    final remaining = durationSeconds - elapsedSeconds;
    if (remaining <= 0) return '0:00';
    final minutes = remaining ~/ 60;
    final seconds = remaining % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class PlaylistSong {
  final String title;
  final String artist;
  final int duration;

  PlaylistSong({
    required this.title,
    required this.artist,
    required this.duration,
  });

  factory PlaylistSong.fromJson(dynamic json) {
    final Map<String, dynamic> song = (json['song'] ?? {}) as Map<String, dynamic>;
    return PlaylistSong(
      title: (song['title'] ?? song['text'] ?? 'Desconocido') as String,
      artist: (song['artist'] ?? '') as String,
      duration: (json['duration'] as num?)?.toInt() ?? 0,
    );
  }
}
