import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:elcontrasteapp/core/di/service_locator.dart';
import 'package:elcontrasteapp/data/local/favorites_store.dart';
import 'package:elcontrasteapp/data/models/post_model.dart';
import 'package:elcontrasteapp/presentation/widgets/favorite_button.dart';
import 'package:elcontrasteapp/presentation/widgets/news_list_tile.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      body: FutureBuilder<Box<String>>(
        future: getIt<FavoritesStore>().box,
        builder: (context, snapshot) {
          final box = snapshot.data;
          if (box == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ValueListenableBuilder<Box<String>>(
            valueListenable: box.listenable(),
            builder: (context, box, _) {
              return FutureBuilder<List<Post>>(
                future: getIt<FavoritesStore>().getAll(),
                builder: (context, postsSnapshot) {
                  final posts = postsSnapshot.data ?? const <Post>[];
                  if (postsSnapshot.connectionState ==
                          ConnectionState.waiting &&
                      posts.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (posts.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text(
                          'Todavía no tienes noticias guardadas.\n'
                          'Toca el ícono de marcador en una noticia para guardarla acá.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index];
                      return NewsListTile(
                        post: post,
                        trailing: FavoriteButton(post: post),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
