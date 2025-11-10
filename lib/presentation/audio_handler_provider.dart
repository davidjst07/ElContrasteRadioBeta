import 'package:audio_service/audio_service.dart';
import 'package:elcontrasteapp/audio_state_service.dart';


AudioHandler? _audioHandler;

Future<AudioHandler> initAudioHandler() async {
  if (_audioHandler != null) return _audioHandler!;

  try {
    _audioHandler = await AudioService.init(
      builder: () => RadioPlayerHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId:
            'com.example.prueba_radio_alpha.channel.audio',
        androidNotificationChannelName: 'Audio playback',
        androidNotificationOngoing: true,
      ),
    );
  } catch (e) {
    // Este error es normal si la instancia ya estaba creada
    print('AudioService ya estaba inicializado: $e');

    // Intentamos obtener la instancia actual si es posible (sin API oficial)
    // como workaround, devolvemos la variable guardada o lanzamos nuevamente el error
    if (_audioHandler != null) {
      return _audioHandler!;
    } else {
      // Aquí Flutter no ofrece API para obtener el handler, por lo que podemos intentar detener primero o dar feedback
      rethrow;
    }
  }

  return _audioHandler!;
}
