import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:audio_service/audio_service.dart';
import 'package:provider/provider.dart';

import 'package:elcontrasteapp/audio_state_service.dart';
import 'package:elcontrasteapp/core/themes/app_theme.dart';
import 'package:elcontrasteapp/presentation/pages/home/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  // Inicializa el audio handler para reproducción en segundo plano
  final audioHandler = await AudioService.init(
    builder: () => RadioPlayerHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.elcontrasteapp.radio.channel',
      androidNotificationChannelName: 'El Contraste Radio',
      androidNotificationChannelDescription: 'Reproducción de radio en vivo',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      preloadArtwork: true,
      // Color negro para la notificación
    ),
  );

  //final audioHandler = await initAudioHandler();

  runApp(
    ChangeNotifierProvider<RadioPlayerHandler>(
      create: (_) => audioHandler as RadioPlayerHandler,
      child: const RadioApp(),
    ),
  );
}

class RadioApp extends StatelessWidget {
  const RadioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'El Contraste App',
      theme: AppTheme.darkTheme,
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
