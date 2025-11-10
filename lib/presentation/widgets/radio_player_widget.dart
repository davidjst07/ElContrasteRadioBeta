import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:elcontrasteapp/audio_state_service.dart';

class RadioPlayerWidget extends StatelessWidget {
  final bool isCompact;

  const RadioPlayerWidget({
    super.key,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<RadioPlayerHandler>(
      builder: (context, audioService, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StreamBuilder<PlayerState>(
              stream: audioService.playerStateStream,
              builder: (context, snapshot) {
                final playerState = snapshot.data ?? audioService.playerState;
                final playing = playerState.playing;
                final processingState = playerState.processingState;

                if (processingState == ProcessingState.loading ||
                    processingState == ProcessingState.buffering) {
                  return SizedBox(
                    height: isCompact ? 48 : 64,
                    width: isCompact ? 48 : 64,
                    child: const CircularProgressIndicator(color: Colors.white),
                  );
                }

                return IconButton(
                  icon: Icon(
                    playing
                        ? Icons.pause_circle_filled_rounded
                        : Icons.play_circle_filled_rounded,
                  ),
                  iconSize: isCompact ? 48.0 : 64.0,
                  color: Colors.white,
                  onPressed: playing ? audioService.pause : audioService.play,
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.volume_down, color: Colors.white70),
                  Flexible(
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
              const SizedBox(height: 8),
              if (audioService.nowPlaying != null)
                Column(
                  children: [
                    Text(
                      'Reproduciendo: ${audioService.nowPlaying?.title ?? 'N/A'}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    Text(
                      'Artista: ${audioService.nowPlaying?.artist ?? 'N/A'}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
            ],
          ],
        );
      },
    );
  }
}
