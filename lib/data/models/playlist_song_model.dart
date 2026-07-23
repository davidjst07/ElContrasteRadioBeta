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
    final Map<String, dynamic> song =
        (json['song'] ?? {}) as Map<String, dynamic>;
    return PlaylistSong(
      title: (song['title'] ?? song['text'] ?? 'Desconocido') as String,
      artist: (song['artist'] ?? '') as String,
      duration: (json['duration'] as num?)?.toInt() ?? 0,
    );
  }
}
