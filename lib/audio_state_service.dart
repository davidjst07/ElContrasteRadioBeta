import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
import 'now_playing_service.dart';

class RadioPlayerHandler extends BaseAudioHandler with ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  String statusMessage = 'Detenido';
  double volume = 1.0;

  NowPlaying? _nowPlaying;
  NowPlaying? get nowPlaying => _nowPlaying;

  Timer? _nowPlayingTimer;

  // Constante para el artwork
  static const String appIcon = 'assets/icon/c_blanca.png';

  RadioPlayerHandler() {
    _init();
    _setupAudioSource();
  }

  void _init() {
    _player.setVolume(volume);

    _player.playerStateStream.listen((state) {
      final playing = state.playing;
      final processingState = state.processingState;

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
          processingState: _mapProcessingState(processingState),
        ),
      );

      _isPlaying = playing;
      statusMessage = playing ? 'Reproduciendo' : 'Pausado';
      notifyListeners();
    });

    _fetchNowPlayingPeriodically();
  }

  Future<void> _setupAudioSource() async {
    try {
      // Configurar el MediaItem inicial
      final initialMediaItem = MediaItem(
        id: AzuraCastService.streamUrl,
        album: 'El Contraste Radio',
        title: 'El Contraste Radio',
        artist: 'Cargando...',
        artUri: Uri.parse(
          'https://elcontraste.co/wp-content/uploads/2023/01/cropped-c-negra-logo.png',
        ),
      );

      this.mediaItem.add(initialMediaItem);

      // Configurar la fuente de audio con la URL del stream
      await _player.setAudioSource(
        AudioSource.uri(
          Uri.parse(AzuraCastService.streamUrl),
          tag: initialMediaItem,
        ),
      );

      print('✅ Fuente de audio configurada: ${AzuraCastService.streamUrl}');
    } catch (e) {
      print('❌ Error configurando fuente de audio: $e');
      statusMessage = 'Error de conexión';
      notifyListeners();
    }
  }

  AudioProcessingState _mapProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  void _fetchNowPlayingPeriodically() {
    _updateNowPlaying();
    _nowPlayingTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _updateNowPlaying(),
    );
  }

  Future<void> _updateNowPlaying() async {
    try {
      final data = await NowPlayingService.getNowPlaying();
      if (data != null) {
        _nowPlaying = data;

        // Actualizar el MediaItem con la información de AzuraCast
        final updatedMediaItem = MediaItem(
          id: AzuraCastService.streamUrl,
          album: 'El Contraste Radio',
          title: data.title != 'Sin información'
              ? data.title
              : 'El Contraste Radio',
          artist: data.artist != 'Artista desconocido'
              ? data.artist
              : 'En Vivo',
          artUri: Uri.parse(
            'https://elcontraste.co/wp-content/uploads/2023/01/cropped-c-negra-logo.png',
          ), // Imagen local
        );

        this.mediaItem.add(updatedMediaItem);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error actualizando NowPlaying: $e');
    }
  }

  /*Future<void> setUrl(String url) async {
    final mediaItem = MediaItem(
      id: url,
      album: 'El Contraste Radio',
      title: 'Emisora Online',
      artist: 'El Contraste',
      artUri: Uri.parse(
        'https://elcontraste.co/wp-content/uploads/2024/04/Logo-el-contraste-RadioRecurso-1.png',
      ),
    );

    this.mediaItem.add(mediaItem);

    // Usa JustAudioBackground para mostrar los controles del sistema
    await _player.setAudioSource(
      AudioSource.uri(
        Uri.parse(url),
        tag: MediaItem(
          id: url,
          album: 'El Contraste Radio',
          title: 'Emisora Online',
          artist: 'El Contraste',
          artUri: Uri.parse(
            'https://elcontraste.co/wp-content/uploads/2024/04/Logo-el-contraste-RadioRecurso-1.png',
          ),
        ),
      ),
    );
  }*/

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  PlayerState get playerState => _player.playerState;

  @override
  Future<void> play() async {
    try {
      statusMessage = 'Conectando...';
      notifyListeners();

      // Verificar si ya tenemos la fuente configurada
      if (_player.audioSource == null) {
        await _setupAudioSource();
      }

      await _player.play();
      statusMessage = 'Reproduciendo';
      notifyListeners();
    } catch (e) {
      statusMessage = 'Error al conectar';
      notifyListeners();
      print('Error al reproducir: $e');
    }
  }

  @override
  Future<void> pause() async {
    try {
      await _player.pause();
      statusMessage = 'Pausado';
      notifyListeners();
    } catch (e) {
      print('Error al pausar: $e');
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _player.stop();
      statusMessage = 'Detenido';
      notifyListeners();
    } catch (e) {
      print('Error al detener: $e');
    }
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
