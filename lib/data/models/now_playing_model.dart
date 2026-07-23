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
    final String? albumArt =
        (links?['art'] as String?) ?? (song['art'] as String?);

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
