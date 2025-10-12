import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

// Esta clase es ahora la única fuente de verdad para el estado de la reproducción de audio.
class AudioStateService with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();

  static const String _radioUrl = 'https://a7.asurahosting.com:7170/radio.mp3';

  double _volume = 0.75;
  String _statusMessage = 'Listo para reproducir';
  PlayerState _playerState = PlayerState.stopped;

  // StreamController para el estado del reproductor, imitando el stream de just_audio
  final StreamController<PlayerState> _playerStateController =
      StreamController.broadcast();

  // Getters para la UI
  double get volume => _volume;
  String get statusMessage => _statusMessage;
  Stream<PlayerState> get playerStateStream => _playerStateController.stream;
  bool get isPlaying => _playerState == PlayerState.playing;

  AudioStateService() {
    _init();
  }

  void _init() {
    // audioplayers usa un modo "release" por defecto que detiene el stream al pausar.
    // Para radio, queremos mantener la conexión.
    _audioPlayer.setReleaseMode(ReleaseMode.stop);

    // Escucha los cambios de estado del reproductor
    _audioPlayer.onPlayerStateChanged.listen((state) {
      _playerState = state;
      _playerStateController.add(state); // Emitir el estado al stream

      switch (state) {
        case PlayerState.playing:
          _statusMessage = 'Reproduciendo en vivo';
          break;
        case PlayerState.paused:
          _statusMessage = 'Pausado';
          break;
        case PlayerState.stopped:
          _statusMessage = 'Toca play para escuchar';
          break;
        case PlayerState.completed:
          _statusMessage = 'Stream finalizado. Toca play para reiniciar.';
          break;
        // audioplayers no tiene un estado de buffering/loading explícito como just_audio.
        // Se maneja internamente. Podemos mostrar 'Cargando' antes de llamar a play.
        default:
          _statusMessage = 'Listo';
      }
      notifyListeners();
    });
  }

  Future<void> play() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        _statusMessage = 'Sin conexión a internet';
        notifyListeners();
        return;
      }

      _statusMessage = 'Cargando radio...';
      notifyListeners();

      // Para audioplayers, play() también maneja la carga de la fuente.
      // Es importante configurar el AudioContext para el comportamiento en segundo plano.
      await _audioPlayer.play(
        UrlSource(_radioUrl),
        volume: _volume,
        ctx: AudioContext(
          android: AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: true,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gain,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: const {},
          ),
        ),
      );
    } on AudioPlayerException catch (e) {
      _statusMessage = 'Error de reproductor';
      notifyListeners();
      debugPrint('Error de audioplayers: $e');
    } catch (e) {
      _statusMessage = 'Error inesperado';
      notifyListeners();
      debugPrint('Error general al reproducir: $e');
    }
  }

  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      debugPrint('Error al pausar: $e');
      _statusMessage = 'Error al pausar';
      notifyListeners();
    }
  }

  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      debugPrint('Error al detener: $e');
      _statusMessage = 'Error al detener';
      notifyListeners();
    }
  }

  Future<void> setVolume(double newVolume) async {
    _volume = newVolume.clamp(0.0, 1.0);
    await _audioPlayer.setVolume(_volume);
    notifyListeners();
  }

  @override
  void dispose() {
    // Es importante liberar los recursos del player.
    _playerStateController.close();
    _audioPlayer.dispose();
    super.dispose();
  }
}
