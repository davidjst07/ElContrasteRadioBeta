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

  String _currentTitle = 'El Contraste Radio';
  String get currentTitle => _currentTitle;

  String _currentSubtitle = 'En Vivo';
  String get currentSubtitle => _currentSubtitle;

  bool _isPlayingEmission = false;
  bool get isPlayingEmission => _isPlayingEmission;

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

      mediaItem.add(initialMediaItem);

      // Configurar la fuente de audio con la URL del stream
      await _player.setAudioSource(
        AudioSource.uri(
          Uri.parse(AzuraCastService.streamUrl),
          tag: initialMediaItem,
        ),
      );

      debugPrint(
        '✅ Fuente de audio configurada: ${AzuraCastService.streamUrl}',
      );
    } catch (e) {
      debugPrint('❌ Error configurando fuente de audio: $e');
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

        if (!_isPlayingEmission) {
          _currentTitle = data.title != 'Sin informacion'
              ? data.title
              : 'El Contraste Radio';
          _currentSubtitle = data.artist.isNotEmpty ? data.artist : 'En Vivo';
        }

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

        mediaItem.add(updatedMediaItem);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error actualizando NowPlaying: $e');
    }
  }

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  PlayerState get playerState => _player.playerState;

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Duration get position => _player.position;
  Duration? get duration => _player.duration;

  Future<void> seekTo(Duration position) async {
    try {
      await _player.seek(position);
    } catch (e) {
      debugPrint('Error moviendo reproduccion: $e');
    }
  }

  Future<void> playEmission({
    required String audioUrl,
    required String title,
    String artist = 'El Contraste Radio',
  }) async {
    try {
      statusMessage = 'Cargando emision...';
      notifyListeners();

      _isPlayingEmission = true;
      _currentTitle = title;
      _currentSubtitle = artist;

      final emissionMediaItem = MediaItem(
        id: audioUrl,
        album: 'Emisiones guardadas',
        title: title,
        artist: artist,
        artUri: Uri.parse(
          'https://elcontraste.co/wp-content/uploads/2023/01/cropped-c-negra-logo.png',
        ),
      );

      mediaItem.add(emissionMediaItem);

      await _player.setAudioSource(
        AudioSource.uri(Uri.parse(audioUrl), tag: emissionMediaItem),
      );

      await _player.play();

      statusMessage = 'Reproduciendo emision';
      notifyListeners();
    } catch (e) {
      statusMessage = 'Error al reproducir emision';
      notifyListeners();
      debugPrint('Error reproduciendo emision: $e');
    }
  }

  Future<void> playLiveRadio() async {
    try {
      statusMessage = 'Conectando en vivo...';
      notifyListeners();

      _isPlayingEmission = false;
      _currentTitle = 'El Contraste Radio';
      _currentSubtitle = 'En Vivo';

      await _setupAudioSource();
      await _player.play();

      statusMessage = 'Reproduciendo en vivo';
      notifyListeners();
    } catch (e) {
      statusMessage = 'Error al conectar en vivo';
      notifyListeners();
      debugPrint('Error reproduciendo radio en vivo: $e');
    }
  }

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
      debugPrint('Error al reproducir: $e');
    }
  }

  @override
  Future<void> pause() async {
    try {
      await _player.pause();
      statusMessage = 'Pausado';
      notifyListeners();
    } catch (e) {
      debugPrint('Error al pausar: $e');
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _player.stop();
      statusMessage = 'Detenido';
      notifyListeners();
    } catch (e) {
      debugPrint('Error al detener: $e');
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
