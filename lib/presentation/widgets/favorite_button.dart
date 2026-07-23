import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:elcontrasteapp/core/di/service_locator.dart';
import 'package:elcontrasteapp/data/local/favorites_store.dart';
import 'package:elcontrasteapp/data/models/post_model.dart';

/// Botón de bookmark reactivo — se actualiza solo cuando cambia el estado
/// de favoritos en Hive, sin necesitar un Cubit para algo tan simple.
class FavoriteButton extends StatelessWidget {
  final Post post;
  final Color? color;

  const FavoriteButton({super.key, required this.post, this.color});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Box<String>>(
      future: getIt<FavoritesStore>().box,
      builder: (context, snapshot) {
        final box = snapshot.data;
        if (box == null) {
          return const SizedBox(width: 24, height: 24);
        }
        return ValueListenableBuilder<Box<String>>(
          valueListenable: box.listenable(),
          builder: (context, box, _) {
            final isFavorite = box.containsKey(post.id.toString());
            return IconButton(
              icon: Icon(
                isFavorite ? Icons.bookmark : Icons.bookmark_border,
                color: color,
              ),
              onPressed: () => getIt<FavoritesStore>().toggle(post),
            );
          },
        );
      },
    );
  }
}
