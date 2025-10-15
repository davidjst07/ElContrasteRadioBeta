import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'now_playing_service.dart';

class AudioStateService extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();

  PlayerState _playerState = PlayerState.stopped;
  PlayerState get playerState => _playerState;

  String statusMessage = 'Detenido';
  double volume = 1.0;

  NowPlaying? _nowPlaying;
  NowPlaying? get nowPlaying => _nowPlaying;

  Stream<PlayerState> get playerStateStream =>
      _audioPlayer.onPlayerStateChanged;

  Timer? _nowPlayingTimer;

  AudioStateService() {
    _init();
  }

  void _init() {
    _audioPlayer.setVolume(volume);
    _audioPlayer.onPlayerStateChanged.listen((state) {
      _playerState = state;
      if (state == PlayerState.playing) {
        statusMessage = 'Reproduciendo';
      } else if (state == PlayerState.paused) {
        statusMessage = 'Pausado';
      } else if (state == PlayerState.stopped) {
        statusMessage = 'Detenido';
      } else if (state == PlayerState.completed) {
        statusMessage = 'Finalizado';
      }
      notifyListeners();
    });

    _fetchNowPlayingPeriodically();
  }

  void _fetchNowPlayingPeriodically() {
    // Carga inmediata y actualizaciones periódicas cada 30 segundos
    _updateNowPlaying();
    _nowPlayingTimer = Timer.periodic(
      Duration(seconds: 30),
      (_) => _updateNowPlaying(),
    );
  }

  Future<void> _updateNowPlaying() async {
    try {
      final data = await NowPlayingService.getNowPlaying();
      if (data != null) {
        _nowPlaying = data;
        notifyListeners();
      }
    } catch (e) {
      print('Error actualizando NowPlaying en AudioStateService: $e');
    }
  }

  Future<void> play() async {
    statusMessage = 'Cargando...';
    notifyListeners();

    try {
      await _audioPlayer.play(UrlSource(AzuraCastService.streamUrl));
      // El cambio a 'Reproduciendo' se capturará desde el listener onPlayerStateChanged
    } catch (e) {
      statusMessage = 'Error al reproducir';
      notifyListeners();
    }
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
    statusMessage = 'Pausado';
    notifyListeners();
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    statusMessage = 'Detenido';
    notifyListeners();
  }

  void setVolume(double newVolume) {
    volume = newVolume;
    _audioPlayer.setVolume(volume);
    notifyListeners();
  }

  @override
  void dispose() {
    _nowPlayingTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
