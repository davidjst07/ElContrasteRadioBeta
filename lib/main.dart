import 'package:audio_service/audio_service.dart';
import 'package:elcontrasteapp/audio_state_service.dart';
import 'package:elcontrasteapp/presentation/audio_handler_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';
import 'package:elcontrasteapp/core/themes/app_theme.dart';
import 'package:elcontrasteapp/presentation/pages/home/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Carga las variables de entorno desde el archivo .env
  await dotenv.load(fileName: ".env");

  // Inicializa just_audio_background para notificación y artwork
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.example.turadio.channel.audio',
    androidNotificationChannelName: 'Radio Playback',
    androidNotificationOngoing: true,
  );

  AudioHandler? audioHandler;
  try {
    audioHandler = await initAudioHandler();
  } catch (e) {
    debugPrint('AudioService initialization error caught: $e');
    // No intentar AudioService.instance, crear dummy para continuar
    audioHandler = DummyAudioHandler();
  }


  runApp(
    ChangeNotifierProvider(
      create: (_) => AudioStateService(),
      child: const RadioApp(),
    ),
  );
}

// Dummy AudioHandler básico para fallback sin funcionalidad
class DummyAudioHandler extends BaseAudioHandler {
  @override
  Future<void> play() async {
    /* noop */
  }
  @override
  Future<void> pause() async {
    /* noop */
  }
  @override
  Future<void> stop() async {
    /* noop */
  }
}

class RadioApp extends StatelessWidget {
  const RadioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'El Contraste App',
      theme: AppTheme.darkTheme,
      home: const HomePage(), // Ahora podemos ir directamente a HomePage
      debugShowCheckedModeBanner: false,
    );
  }
}
