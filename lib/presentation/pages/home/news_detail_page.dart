import 'package:elcontrasteapp/data/models/post_model.dart';
import 'package:elcontrasteapp/presentation/widgets/app_network_image.dart';
import 'package:elcontrasteapp/presentation/widgets/favorite_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class NewsDetailPage extends StatelessWidget {
  final Post post;

  const NewsDetailPage({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(post.title),
        actions: [FavoriteButton(post: post)],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.featuredImageUrl != null)
              Hero(
                tag: 'news_image_${post.id}',
                child: AppNetworkImage(
                  imageUrl: post.featuredImageUrl!,
                  width: double.infinity,
                  height: 250,
                  errorIcon: Icons.error,
                ),
              ),
            /*Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Leer más",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              */
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Html(
                data: post.content,
                style: {
                  "body": Style(
                    margin: Margins.zero,
                    padding: HtmlPaddings.zero,
                  ),
                },
                extensions: [
                  TagExtension(
                    tagsToExtend: const {'img'},
                    builder: (ExtensionContext context) {
                      final src = context.attributes['src'];
                      if (src != null) {
                        return AppNetworkImage(
                          imageUrl: src,
                          fit: BoxFit.fitWidth,
                          errorIcon: Icons.broken_image,
                        );
                      }
                      return Container();
                    },
                  ),
                ],
                onLinkTap: (url, _, __) {
                  // Aquí puedes agregar lógica para abrir enlaces si lo necesitas en el futuro
                  debugPrint("Tapped on link: $url");
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
