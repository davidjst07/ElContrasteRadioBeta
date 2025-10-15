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
      final response = await http.get(
        Uri.parse('$_baseUrl/nowplaying'),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'ElContrasteRadioApp/1.0',
        },
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return NowPlaying.fromJson(json);
      } else {
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
  final String? nowPlayingTitle;
  final String? nowPlayingArtist;
  final String? nowPlayingAlbum;
  final int listeners;
  final int uniqueListeners;
  final String? playlistName;
  final int elapsedSeconds;
  final int durationSeconds;
  final String? albumArtUrl;

  NowPlaying({
    this.nowPlayingTitle,
    this.nowPlayingArtist,
    this.nowPlayingAlbum,
    required this.listeners,
    required this.uniqueListeners,
    this.playlistName,
    required this.elapsedSeconds,
    required this.durationSeconds,
    this.albumArtUrl,
  });

  factory NowPlaying.fromJson(Map<String, dynamic> json) {
    final nowPlaying = json['now_playing'] ?? {};
    final song = nowPlaying['song'] ?? {};
    final links = song['links'] ?? {};

    return NowPlaying(
      nowPlayingTitle: song['title'] ?? 'Sin información',
      nowPlayingArtist: song['artist'] ?? 'Artista desconocido',
      nowPlayingAlbum: song['album'],
      listeners: json['listeners']?['current'] ?? 0,
      uniqueListeners: json['listeners']?['unique'] ?? 0,
      playlistName: nowPlaying['playlist'] ?? 'AutoDJ',
      elapsedSeconds: nowPlaying['elapsed'] ?? 0,
      durationSeconds: nowPlaying['duration'] ?? 0,
      albumArtUrl: links['art'],
    );
  }

  double getProgress() {
    if (durationSeconds == 0) return 0;
    return (elapsedSeconds / durationSeconds).clamp(0.0, 1.0);
  }

  String getRemainingTime() {
    final remaining = durationSeconds - elapsedSeconds;
    if (remaining < 0) return '0:00';
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
    final links = json['links'] ?? {};

    return StationInfo(
      name: json['name'] ?? 'Sin nombre',
      description: json['description'] ?? '',
      genre: json['genre'] ?? 'Variado',
      url: json['url'] ?? '',
      listeners: json['listeners']?['current'] ?? 0,
      iconUrl: links['icon'],
    );
  }
}
