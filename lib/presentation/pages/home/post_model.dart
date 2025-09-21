

class Post {
  final int id;
  final String title;
  final String excerpt;
  final String content;
  final String? featuredImageUrl;

  Post({
    required this.id,
    required this.title,
    required this.excerpt,
    required this.content,
    this.featuredImageUrl,
  });

  // El factory constructor nos permite crear una instancia de Post
  // a partir del JSON que nos devuelve la API de WordPress.
  factory Post.fromJson(Map<String, dynamic> json) {
    String? imageUrl;
    // El parámetro _embed nos permite acceder a la información de la imagen destacada.
    // A veces puede no venir, por eso hacemos estas validaciones.
    if (json['_embedded'] != null &&
        json['_embedded']['wp:featuredmedia'] != null &&
        json['_embedded']['wp:featuredmedia'][0] != null) {
      imageUrl = json['_embedded']['wp:featuredmedia'][0]['source_url'];
    }

    // Limpiamos un poco el texto que viene de la API.
    final title = json['title']['rendered'].replaceAll('&#8211;', '–');
    final excerpt = json['excerpt']['rendered'].replaceAll(
      RegExp(r'<[^>]*>'),
      '',
    );

    return Post(
      id: json['id'],
      title: title,
      excerpt: excerpt,
      content: json['content']['rendered'],
      featuredImageUrl: imageUrl,
    );
  }
}
