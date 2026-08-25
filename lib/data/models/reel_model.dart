class Reel {
  final String id;
  final String urlHls;
  final String thumbnailUrl;
  final String titulo;
  final int duracionSeg;
  final DateTime creadoEn;
  // Contador de likes del servidor. Default 0: el backend puede no
  // mandar este campo todavía (endpoint de likes pendiente de desplegar).
  final int likesCount;

  Reel({
    required this.id,
    required this.urlHls,
    required this.thumbnailUrl,
    required this.titulo,
    required this.duracionSeg,
    required this.creadoEn,
    this.likesCount = 0,
  });

  // Constructor para parsear desde el JSON del endpoint (usa snake_case)
  factory Reel.fromJson(Map<String, dynamic> json) {
    return Reel(
      id: json['id'] as String,
      urlHls: json['url_hls'] as String,
      thumbnailUrl: json['thumbnail_url'] as String,
      titulo: json['titulo'] as String,
      duracionSeg: json['duracion_seg'] as int,
      creadoEn: DateTime.parse(json['creado_en'] as String),
      likesCount: json['likes_count'] as int? ?? 0,
    );
  }
}
