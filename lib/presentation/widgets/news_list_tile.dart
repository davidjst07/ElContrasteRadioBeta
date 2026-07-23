import 'package:flutter/material.dart';

import 'package:elcontrasteapp/core/themes/app_theme.dart';
import 'package:elcontrasteapp/core/utils/date_formatter.dart';
import 'package:elcontrasteapp/data/models/post_model.dart';
import 'package:elcontrasteapp/presentation/pages/home/news_detail_page.dart';
import 'package:elcontrasteapp/presentation/widgets/app_network_image.dart';

/// Tarjeta compacta para listas verticales normales (Favoritos, Buscador) —
/// a diferencia de `_NewsCard` del feed principal, que ocupa la pantalla
/// completa por el diseño de swipe del `PageView`.
class NewsListTile extends StatelessWidget {
  final Post post;
  final Widget? trailing;

  const NewsListTile({super.key, required this.post, this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeColors = context.themeColors;

    return Card(
      color: themeColors.cardColor,
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => NewsDetailPage(post: post)),
          );
        },
        leading: post.featuredImageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AppNetworkImage(
                  imageUrl: post.featuredImageUrl!,
                  width: 64,
                  height: 64,
                  placeholderBackground: themeColors.placeholderColor,
                ),
              )
            : null,
        title: Text(
          post.title,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(formatRelativeDate(post.date)),
        trailing: trailing,
      ),
    );
  }
}
