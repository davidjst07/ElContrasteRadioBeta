import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AudioService extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  static const String RADIO_URL = 'https://stream.zeno.fm/3u4rvdaxhrhvv';

  double _volume = 0.75;
  String _statusMessage = 'Listo para reproducir';

  // Getters
  double get volume => _volume;
  String get statusMessage => _statusMessage;
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;

  AudioService() {
    _initialize();
  }

  void _initialize() async {
    _audioPlayer.setVolume(_volume);
    // Configurar la fuente de audio con metadatos para el segundo plano
    final audioSource = AudioSource.uri(
      Uri.parse(RADIO_URL),
      tag: MediaItem(
        id: 'el_contraste_radio_live',
        album: "Radio en Vivo",
        title: "El Contraste Radio",
        artUri: Uri.parse(
            "https://cdn.zeno.fm/stations/3u4rvdaxhrhvv/uploads/ec/logo/elcontraste-cuadrado.png"),
      ),
    );
    try {
      await _audioPlayer.setAudioSource(audioSource, preload: false);
    } catch (e) {
      print("Error al configurar la fuente de audio: $e");
      _statusMessage = "Error al iniciar la radio";
      notifyListeners();
    }
  }

  Future<void> play() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        _statusMessage = 'Sin conexión a internet';
        notifyListeners();
        return;
      }
      _audioPlayer.play();
    } catch (e) {
      _statusMessage = 'Error al conectar';
      notifyListeners();
      print('Error al reproducir radio: $e');
    }
  }

  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      print('Error al pausar radio: $e');
      _statusMessage = 'Error al pausar';
      notifyListeners();
    }
  }

  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      // just_audio se queda en estado 'completed', lo volvemos a preparar
      _initialize();
    } catch (e) {
      print('Error al detener radio: $e');
    }
  }

  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _audioPlayer.setVolume(_volume);
    notifyListeners();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}

class RadioPlayerWidget extends StatelessWidget {
  const RadioPlayerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final audioService = Provider.of<AudioService>(context, listen: false);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        StreamBuilder<PlayerState>(
          stream: audioService.playerStateStream,
          builder: (context, snapshot) {
            final playerState = snapshot.data;
            final processingState = playerState?.processingState;
            final isPlaying = playerState?.playing ?? false;

            if (processingState == ProcessingState.loading ||
                processingState == ProcessingState.buffering) {
              return const CircularProgressIndicator(color: Colors.white);
            }

            return IconButton(
              icon: Icon(
                isPlaying
                    ? Icons.pause_circle_filled_rounded
                    : Icons.play_circle_filled_rounded,
              ),
              iconSize: 64.0,
              color: Colors.white,
              onPressed: () {
                if (isPlaying) {
                  audioService.pause();
                } else {
                  audioService.play();
                }
              },
            );
          },
        ),
        const SizedBox(height: 8),
        Consumer<AudioService>(
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
              child: Consumer<AudioService>(
                builder: (context, service, child) => Slider(
                  value: service.volume,
                  onChanged: (newVolume) {
                    service.setVolume(newVolume);
                  },
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
