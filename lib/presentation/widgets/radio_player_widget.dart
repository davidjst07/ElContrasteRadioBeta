import 'package:elcontrasteapp/audio_state_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';

class RadioPlayerWidget extends StatelessWidget {
  final bool isCompact;

  const RadioPlayerWidget({
    super.key,
    this.isCompact = false, // Por defecto no es compacto
  });

  @override
  Widget build(BuildContext context) {
    // Usamos Consumer para que solo este widget se reconstruya cuando cambie el estado del audio.
    return Consumer<AudioStateService>(
      builder: (context, audioService, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StreamBuilder<PlayerState>(
              stream: audioService.playerStateStream,
              builder: (context, snapshot) {
                final playerState = snapshot.data ?? PlayerState.stopped;

                // En audioplayers, no tenemos un estado de buffering explícito.
                // Mostramos el indicador de carga basado en el mensaje de estado.
                if (audioService.statusMessage.contains('Cargando')) {
                  // En modo compacto, el botón es más pequeño.
                  return SizedBox(
                    height: isCompact ? 48 : 64,
                    width: isCompact ? 48 : 64,
                    child: const CircularProgressIndicator(color: Colors.white),
                  );
                }

                final isPlaying = playerState == PlayerState.playing;
                return IconButton(
                  icon: Icon(
                    isPlaying
                        ? Icons.pause_circle_filled_rounded
                        : Icons.play_circle_filled_rounded,
                  ),
                  iconSize: isCompact ? 48.0 : 64.0,
                  color: Colors.white,
                  onPressed: isPlaying ? audioService.pause : audioService.play,
                );
              },
            ),
            if (!isCompact) ...[
              const SizedBox(height: 8),
              Text(
                audioService.statusMessage,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize:
                    MainAxisSize.min, // 👈 evita el error de constraints
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.volume_down, color: Colors.white70),
                  Flexible(
                    // 👈 reemplaza Expanded por Flexible
                    fit: FlexFit.loose,
                    child: Slider(
                      value: audioService.volume,
                      onChanged: audioService.setVolume,
                      min: 0.0,
                      max: 1.0,
                      activeColor: Colors.white,
                      inactiveColor: Colors.white30,
                    ),
                  ),
                  const Icon(Icons.volume_up, color: Colors.white70),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}
