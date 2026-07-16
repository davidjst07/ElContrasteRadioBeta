class RadioEmission {
  final int id;
  final String title;
  final DateTime start;
  final DateTime? end;
  final int? durationSeconds;
  final int? sizeBytes;
  final String audioUrl;

  const RadioEmission({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    required this.durationSeconds,
    required this.sizeBytes,
    required this.audioUrl,
  });

  factory RadioEmission.fromJson(Map<String, dynamic> json) {
    return RadioEmission(
      id: json['id'] as int,
      title: json['titulo'] as String? ?? 'Emision',
      start: DateTime.parse(json['inicio'] as String).toLocal(),
      end: json['fin'] == null
          ? null
          : DateTime.parse(json['fin'] as String).toLocal(),
      durationSeconds: (json['duracionSegundos'] as num?)?.toInt(),
      sizeBytes: (json['tamanoBytes'] as num?)?.toInt(),
      audioUrl: json['urlAudio'] as String,
    );
  }

  String get displayDayName {
    const days = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];

    return days[start.weekday - 1];
  }

  String get displayTitle {
    final date = '${_two(start.day)}/${_two(start.month)}/${start.year}';
    final day = displayDayName;

    if (title.trim().isEmpty || title == 'Emision') {
      return 'Emision del $day $date';
    }

    return '$title - $day $date';
  }

  String get displayTime {
    final startText = '${_two(start.hour)}:${_two(start.minute)}';

    if (end == null) {
      return startText;
    }

    final endText = '${_two(end!.hour)}:${_two(end!.minute)}';
    return '$startText - $endText';
  }

  String get displayDuration {
    final seconds = durationSeconds;

    if (seconds == null) {
      return '';
    }

    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}min';
    }

    return '${minutes}min';
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}
