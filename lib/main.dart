import 'package:elcontrasteapp/audio_state_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';
import 'package:elcontrasteapp/core/themes/app_theme.dart';
import 'package:elcontrasteapp/presentation/pages/home/home_page.dart';

Future<void> main() async {
  // Asegura que los bindings de Flutter estén inicializados antes de llamar a código nativo.
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa los servicios en el orden correcto.
  await JustAudioBackground.init(
    androidNotificationChannelId: 'co.elcontraste.app.channel.audio',
    androidNotificationChannelName: 'Reproducción de Audio',
    androidNotificationOngoing: true,
    // Añadimos el ícono para la barra de estado.
    // Usaremos el ícono de la app, que sabemos que existe.
    // Usaremos nuestra imagen PNG personalizada.
    // El nombre debe coincidir con el archivo que pusiste en la carpeta `drawable`.
    //androidNotificationIcon: 'assets/icon/ic_radio_blanco.png',
  );
  await dotenv.load(fileName: ".env");

  runApp(
    ChangeNotifierProvider(
      create: (_) => AudioStateService(),
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
      home: const HomePage(), // Ahora podemos ir directamente a HomePage
      debugShowCheckedModeBanner: false,
    );
  }
}
