import 'package:elcontrasteapp/core/utils/html_utils.dart';

class Post {
  final int id;
  final String title;
  final String excerpt;
  final String content;
  final String? featuredImageUrl;
  final DateTime date;

  // El constructor y los métodos deben estar DENTRO de la clase.
  Post({
    required this.id,
    required this.title,
    required this.excerpt,
    required this.content,
    this.featuredImageUrl,
    required this.date,
  });

  // La palabra clave es "factory" en minúsculas.
  factory Post.fromJson(Map<String, dynamic> json) {
    String? imageUrl;
    if (json['_embedded'] != null &&
        json['_embedded']['wp:featuredmedia'] != null &&
        (json['_embedded']['wp:featuredmedia'] as List).isNotEmpty) {
      imageUrl = json['_embedded']['wp:featuredmedia'][0]['source_url'];
    }

    final date = DateTime.parse(json['date']);
    final title = json['title']['rendered'].replaceAll('&#8211;', '-');
    final excerpt = stripHtmlTags(json['excerpt']['rendered']);

    return Post(
      id: json['id'],
      title: title,
      excerpt: excerpt,
      content: json['content']['rendered'],
      featuredImageUrl: imageUrl,
      date: date,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'excerpt': excerpt,
    'content': content,
    'featuredImageUrl': featuredImageUrl,
    'date': date.toIso8601String(),
  };

  factory Post.fromCacheJson(Map<String, dynamic> json) => Post(
    id: json['id'] as int,
    title: json['title'] as String,
    excerpt: json['excerpt'] as String,
    content: json['content'] as String,
    featuredImageUrl: json['featuredImageUrl'] as String?,
    date: DateTime.parse(json['date'] as String),
  );
}
