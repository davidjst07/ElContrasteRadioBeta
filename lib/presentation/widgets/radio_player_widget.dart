import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:elcontrasteapp/presentation/audio/radio_player_handler.dart';

class RadioPlayerWidget extends StatelessWidget {
  final bool isCompact;

  const RadioPlayerWidget({super.key, this.isCompact = false});

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildProgressBar(RadioPlayerHandler audioService) {
    return StreamBuilder<Duration?>(
      stream: audioService.durationStream,
      builder: (context, durationSnapshot) {
        final duration = durationSnapshot.data ?? audioService.duration;

        if (duration == null || duration.inSeconds <= 0) {
          return const SizedBox.shrink();
        }

        return StreamBuilder<Duration>(
          stream: audioService.positionStream,
          builder: (context, positionSnapshot) {
            final position = positionSnapshot.data ?? audioService.position;
            final safePosition = position > duration ? duration : position;

            return Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.35),
                    thumbColor: Colors.white,
                    overlayColor: Colors.white.withValues(alpha: 0.18),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: safePosition.inMilliseconds.toDouble(),
                    min: 0,
                    max: duration.inMilliseconds.toDouble(),
                    onChanged: (value) {
                      audioService.seekTo(
                        Duration(milliseconds: value.round()),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(safePosition),
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Text(
                        _formatDuration(duration),
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

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
              _buildProgressBar(audioService),
              const SizedBox(height: 8),
              Column(
                children: [
                  Text(
                    audioService.isPlayingEmission
                        ? 'Emision guardada: ${audioService.currentTitle}'
                        : 'Reproduciendo: ${audioService.currentTitle}',
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    audioService.currentSubtitle,
                    style: const TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
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
