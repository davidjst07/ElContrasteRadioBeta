import 'package:elcontrasteapp/audio_state_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:elcontrasteapp/core/themes/app_theme.dart';
import 'package:elcontrasteapp/presentation/pages/home/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // audioplayers no requiere una inicialización asíncrona aquí.

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
