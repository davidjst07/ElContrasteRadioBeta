import 'package:elcontrasteapp/presentation/blocs/notifications/notifications_bloc.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:audio_service/audio_service.dart';
import 'package:provider/provider.dart';

import 'package:elcontrasteapp/audio_state_service.dart';
import 'package:elcontrasteapp/core/themes/app_theme.dart';
import 'package:elcontrasteapp/presentation/pages/home/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await NotificationsBloc.initializeFCM();

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
    MultiBlocProvider(
      providers: [BlocProvider(create: (_) => NotificationsBloc())],
      child: ChangeNotifierProvider<RadioPlayerHandler>(
        create: (_) => audioHandler as RadioPlayerHandler,
        child: const RadioApp(),
      ),
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
      builder: (context, child) =>
          HandleNotificationsInteractions(child: child!),
    );
  }
}

class HandleNotificationsInteractions extends StatefulWidget {
  final Widget child;

  const HandleNotificationsInteractions({super.key, required this.child});

  @override
  State<HandleNotificationsInteractions> createState() =>
      _HandleNotificationsInteractionsState();
}

class _HandleNotificationsInteractionsState
    extends State<HandleNotificationsInteractions> {
  // It is assumed that all messages contain a data field with the key 'type'
  Future<void> setupInteractedMessage() async {
    // Get any messages which caused the application to open from
    // a terminated state.
    RemoteMessage? initialMessage = await FirebaseMessaging.instance
        .getInitialMessage();

    // If the message also contains a data property with a "type" of "chat",
    // navigate to a chat screen
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // Also handle any interaction when the app is in the background via a
    // Stream listener
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  void _handleMessage(RemoteMessage message) {
    context.read<NotificationsBloc>()
    .handleRemoteMessage(message);

    if (message.data['type'] == 'chat') {
      Navigator.pushNamed(context, '/chat', 
        arguments: message,  // Pasa directamente el RemoteMessage

      );
    }
  }

  @override
  void initState() {
    super.initState();

    // Run code required to handle interacted messages in an async function
    // as initState() must not be async
    setupInteractedMessage();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
