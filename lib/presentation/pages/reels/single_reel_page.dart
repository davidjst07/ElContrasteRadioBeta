import 'package:flutter/material.dart';
import 'package:elcontrasteapp/data/models/reel_model.dart';
import 'package:elcontrasteapp/presentation/pages/reels/reels_page.dart';
import 'package:elcontrasteapp/presentation/widgets/reel_player.dart';

/// Pantalla que muestra UN solo reel a pantalla completa.
/// Se usa cuando la app se abre desde un deep link
/// (elcontraste://reel/{id}) o desde una notificación push,
/// en vez de cargar todo el feed paginado.
class SingleReelPage extends StatelessWidget {
  final Reel reel;

  const SingleReelPage({super.key, required this.reel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          ReelPlayerWidget(reel: reel, isActive: true),

          // Botón atrás
          Positioned(
            top: 16,
            left: 8,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),

          // Título + botón para ver más reels (arriba de los controles)
          Positioned(
            bottom: 90,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  reel.titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    // Reemplaza esta pantalla por el feed completo de reels
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const ReelsPage(showAppBar: true),
                      ),
                    );
                  },
                  icon: const Icon(Icons.explore, color: Colors.white),
                  label: const Text(
                    'Ver más reels',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
