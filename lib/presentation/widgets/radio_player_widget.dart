
import 'package:elcontrasteapp/audio_state_service.dart';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

class RadioPlayerWidget extends StatelessWidget {
  const RadioPlayerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtenemos la instancia única de AudioStateService desde el provider.
    // Ponemos listen: false para evitar reconstruir toda la columna en cada cambio,
    // ya que los Consumers se encargarán de reconstrucciones específicas.
    final audioService = Provider.of<AudioStateService>(context, listen: false);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        StreamBuilder<PlayerState>(
          stream: audioService.playerStateStream,
          builder: (context, snapshot) {
            final playerState = snapshot.data;
            final processingState = playerState?.processingState;

            if (processingState == ProcessingState.loading ||
                processingState == ProcessingState.buffering) {
              return const CircularProgressIndicator(color: Colors.white);
            }

            final isPlaying = playerState?.playing ?? false;
            return IconButton(
              icon: Icon(
                isPlaying
                    ? Icons.pause_circle_filled_rounded
                    : Icons.play_circle_filled_rounded,
              ),
              iconSize: 64.0,
              color: Colors.white,
              onPressed: isPlaying ? audioService.pause : audioService.play,
            );
          },
        ),
        const SizedBox(height: 8),
        // Consumer solo reconstruye este widget de Texto cuando statusMessage cambia.
        Consumer<AudioStateService>(
          builder: (context, service, child) {
            return Text(
              service.statusMessage,
              style: const TextStyle(color: Colors.white70),
            );
          },
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.volume_down, color: Colors.white70),
            Expanded(
              // Consumer solo reconstruye el Slider cuando el volumen cambia.
              child: Consumer<AudioStateService>(
                builder: (context, service, child) => Slider(
                  value: service.volume,
                  onChanged: service.setVolume,
                  min: 0.0,
                  max: 1.0,
                  activeColor: Colors.white,
                  inactiveColor: Colors.white30,
                ),
              ),
            ),
            const Icon(Icons.volume_up, color: Colors.white70),
          ],
        ),
      ],
    );
  }
}
