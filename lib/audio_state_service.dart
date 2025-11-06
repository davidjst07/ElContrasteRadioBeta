import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
import 'now_playing_service.dart'; // Tu servicio para obtener metadata externa

class AudioHandlerWithNowPlaying extends BaseAudioHandler {
  final AudioPlayer _player = AudioPlayer();

  PlayerState _playerState = PlayerState.stopped;
  PlayerState get playerState => _playerState;

  String statusMessage = 'Detenido';
  double volume = 1.0;

  NowPlaying? _nowPlaying;
  NowPlaying? get nowPlaying => _nowPlaying;

  Timer? _nowPlayingTimer;

  AudioHandlerWithNowPlaying() {
    _init();
  }

  void _init() {
    _player.setVolume(volume);

    // Escucha estado de reproducción y actualiza playbackState de audio_service
    _player.playbackEventStream.listen((event) {
      final playing = _player.playing;
      final processingState = event.processingState;
      playbackState.add(
        playbackState.value.copyWith(
          controls: [
            MediaControl.stop,
            if (playing) MediaControl.pause else MediaControl.play,
          ],
          systemActions: const {
            MediaAction.seek,
            MediaAction.pause,
            MediaAction.play,
            MediaAction.stop,
          },
          playing: playing,
          processingState: {
            ProcessingState.idle: AudioProcessingState.idle,
            ProcessingState.loading: AudioProcessingState.loading,
            ProcessingState.buffering: AudioProcessingState.buffering,
            ProcessingState.ready: AudioProcessingState.ready,
            ProcessingState.completed: AudioProcessingState.completed,
          }[processingState]!,
        ),
      );

      // Actualiza estado local para UI adicional
      _playerState = playing ? PlayerState.playing : PlayerState.paused;
      statusMessage = playing ? 'Reproduciendo' : 'Pausado';

      notifyListeners();
    });

    _fetchNowPlayingPeriodically();
  }

  void _fetchNowPlayingPeriodically() {
    _updateNowPlaying();
    _nowPlayingTimer = Timer.periodic(
      const Duration(seconds: 30),
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
      debugPrint('Error actualizando NowPlaying: $e');
    }
  }

  Future<void> setUrl(String url) async {
    final mediaItem = MediaItem(
      id: url,
      album: 'Tu emisora',
      title: 'Emisora Online',
      artist: 'AzuraCast',
      artUri: Uri.parse(
        'https://elcontraste.co/wp-content/uploads/2024/04/Logo-el-contraste-RadioRecurso-1.png',
      ),
    );

    this.mediaItem.add(mediaItem);

    await _player.setAudioSource(AudioSource.uri(Uri.parse(url), tag: mediaItem));
  }

  @override
  Future<void> play() async {
    statusMessage = 'Cargando...';
    notifyListeners();
    await _player.play();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
    statusMessage = 'Pausado';
    notifyListeners();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    statusMessage = 'Detenido';
    notifyListeners();
    return super.stop();
  }

  void setVolume(double newVolume) {
    volume = newVolume;
    _player.setVolume(volume);
    notifyListeners();
  }

  @override
  void dispose() {
    _nowPlayingTimer?.cancel();
    _player.dispose();
    super.dispose();
  }
}
