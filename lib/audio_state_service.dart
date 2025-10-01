import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

// Esta clase es ahora la única fuente de verdad para el estado de la reproducción de audio.
class AudioStateService with ChangeNotifier {
  // Creamos nuestra propia instancia. just_audio_background la detectará.
  final AudioPlayer _audioPlayer = AudioPlayer();

  static const String _radioUrl = 'https://stream.zeno.fm/3u4rvdaxhrhvv';

  bool _isSourcePrepared = false;
  double _volume = 0.75;
  String _statusMessage = 'Listo para reproducir';

  // Getters para la UI
  double get volume => _volume;
  String get statusMessage => _statusMessage;
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;
  bool get isPlaying => _audioPlayer.playing;

  AudioStateService() {
    _init();
  }

  void _init() {
    // Escucha los cambios de estado del reproductor para actualizar la UI
    _audioPlayer.playerStateStream.listen((state) {
      switch (state.processingState) {
        case ProcessingState.idle:
          // Cuando el reproductor está inactivo (después de stop() o al inicio).
          _statusMessage = 'Toca play para escuchar';
          _isSourcePrepared =
              false; // Forzamos a preparar la fuente de nuevo en el próximo play.
          break;
        case ProcessingState.loading:
          _statusMessage = 'Cargando radio...';
          break;
        case ProcessingState.buffering:
          _statusMessage = 'Cargando...';
          break;
        case ProcessingState.ready:
          _statusMessage = state.playing ? 'Reproduciendo en vivo' : 'Pausado';
          break;
        case ProcessingState.completed:
          // Para un stream en vivo, 'completed' puede significar un error o que se detuvo.
          _statusMessage = 'Stream finalizado. Toca play para reiniciar.';
          break;
      }
      notifyListeners();
    });
    // La fuente de audio se preparará la primera vez que se presione play.
  }

  Future<void> _prepareAudioSource() async {
    await _audioPlayer.setVolume(_volume);
    // Configura la fuente de audio con metadatos para la reproducción en segundo plano
    final audioSource = AudioSource.uri(
      Uri.parse(_radioUrl),
      tag: MediaItem(
        id: 'el_contraste_radio_live',
        album: "Radio en Vivo",
        title: "El Contraste Radio",
        artUri: Uri.parse(
          "https://cdn.zeno.fm/stations/3u4rvdaxhrhvv/uploads/ec/logo/elcontraste-cuadrado.png",
        ),
      ),
    );
    try {
      // No precargamos hasta que el usuario presione play
      await _audioPlayer.setAudioSource(audioSource, preload: false);
      _isSourcePrepared = true;
    } catch (e) {
      debugPrint("Error al configurar la fuente de audio: $e");
      _statusMessage = "Error al iniciar la radio";
      notifyListeners();
    }
  }

  Future<void> play() async {
    // Prepara la fuente de audio de forma perezosa si aún no se ha hecho.
    if (!_isSourcePrepared) {
      await _prepareAudioSource();
      // Si la preparación falló, no continuamos.
      if (!_isSourcePrepared) {
        debugPrint('No se pudo preparar la fuente de audio, abortando play().');
        return;
      }
    }

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        _statusMessage = 'Sin conexión a internet';
        notifyListeners();
        return;
      }
      await _audioPlayer.play();
    } catch (e) {
      _statusMessage = 'Error al conectar';
      notifyListeners();
      debugPrint('Error al reproducir radio: $e');
    }
  }

  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      debugPrint('Error al pausar radio: $e');
      _statusMessage = 'Error al pausar';
      notifyListeners();
    }
  }

  // El paquete just_audio_background llamará a este método
  // cuando se presione el botón de stop en la notificación.
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      debugPrint('Error al detener la radio: $e');
      _statusMessage = 'Error al detener';
      notifyListeners();
    }
  }

  Future<void> setVolume(double newVolume) async {
    _volume = newVolume.clamp(0.0, 1.0);
    await _audioPlayer.setVolume(_volume);
    notifyListeners();
  }

  
  // No debemos hacer dispose del player, ya que el servicio de fondo
  // debe seguir funcionando aunque la UI se destruya.
  // El sistema operativo se encargará de liberar los recursos cuando sea necesario.
  // void dispose() {
  //   _audioPlayer.dispose();
  //   super.dispose();
  // }
}
