import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AzuraCastService {
  static const String streamUrl = 'https://a7.asurahosting.com:7170/radio.mp3';
}

class NowPlayingService {
  static const String _baseUrl = 'https://a7.asurahosting.com/api/station/588';

  static Future<NowPlaying?> getNowPlaying() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/nowplaying'),
            headers: {
              'Accept': 'application/json',
              'User-Agent': 'ElContrasteRadioApp/1.0',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        return NowPlaying.fromJson(json);
      } else {
        // Puedes loguear más info aquí si lo deseas
        print('Error: Código de estado ${response.statusCode}');
        return null;
      }
    } on TimeoutException catch (_) {
      print('Timeout al conectar con la API');
      return null;
    } catch (e) {
      print('Error obteniendo now playing: $e');
      return null;
    }
  }
}

class NowPlaying {
  // Campos renombrados a nombres cortos y usados por la UI
  final String title;
  final String artist;
  final String? album;
  final int listeners;
  final int uniqueListeners;
  final String playlistName;
  final int elapsedSeconds;
  final int durationSeconds;
  final String? albumArtUrl;

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
  });

  factory NowPlaying.fromJson(Map<String, dynamic> json) {
    // Estructura típica de AzuraCast: { "now_playing": { "song": { ... }, "elapsed": .., "duration": .. }, "listeners": { "current": .., "unique": .. } }
    final Map<String, dynamic> nowPlaying = (json['now_playing'] is Map)
        ? json['now_playing'] as Map<String, dynamic>
        : {};
    final Map<String, dynamic> song = (nowPlaying['song'] is Map)
        ? nowPlaying['song'] as Map<String, dynamic>
        : {};
    final Map<String, dynamic> links = (song['links'] is Map)
        ? song['links'] as Map<String, dynamic>
        : {};

    final String title =
        (song['title'] as String?)?.trim() ?? 'Sin información';
    final String artist =
        (song['artist'] as String?)?.trim() ?? 'Artista desconocido';
    final String? album = (song['album'] as String?)?.trim();

    final int listeners = (json['listeners'] is Map)
        ? (json['listeners']['current'] as int? ?? 0)
        : 0;
    final int uniqueListeners = (json['listeners'] is Map)
        ? (json['listeners']['unique'] as int? ?? 0)
        : 0;

    final String playlistName =
        (nowPlaying['playlist'] as String?)?.trim() ?? 'AutoDJ';

    final int elapsed = (nowPlaying['elapsed'] is int)
        ? nowPlaying['elapsed'] as int
        : int.tryParse('${nowPlaying['elapsed']}') ?? 0;
    final int duration = (nowPlaying['duration'] is int)
        ? nowPlaying['duration'] as int
        : int.tryParse('${nowPlaying['duration']}') ?? 0;

    final String? albumArt = (links['art'] as String?)?.trim();

    return NowPlaying(
      title: title,
      artist: artist,
      album: album,
      listeners: listeners,
      uniqueListeners: uniqueListeners,
      playlistName: playlistName,
      elapsedSeconds: elapsed,
      durationSeconds: duration,
      albumArtUrl: albumArt,
    );
  }

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

  String getElapsedTime() {
    final minutes = elapsedSeconds ~/ 60;
    final seconds = elapsedSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String getDurationFormatted() {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class StationInfo {
  final String name;
  final String description;
  final String genre;
  final String url;
  final int listeners;
  final String? iconUrl;

  StationInfo({
    required this.name,
    required this.description,
    required this.genre,
    required this.url,
    required this.listeners,
    this.iconUrl,
  });

  factory StationInfo.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> links = (json['links'] is Map)
        ? json['links'] as Map<String, dynamic>
        : {};

    return StationInfo(
      name: (json['name'] as String?)?.trim() ?? 'Sin nombre',
      description: (json['description'] as String?)?.trim() ?? '',
      genre: (json['genre'] as String?)?.trim() ?? 'Variado',
      url: (json['url'] as String?)?.trim() ?? '',
      listeners: (json['listeners'] is Map)
          ? (json['listeners']['current'] as int? ?? 0)
          : 0,
      iconUrl: (links['icon'] as String?)?.trim(),
    );
  }
}
