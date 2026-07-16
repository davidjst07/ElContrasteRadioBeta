import 'package:elcontrasteapp/config/local_notifications/local_notifications.dart';
import 'package:elcontrasteapp/core/themes/app_theme.dart';
import 'package:elcontrasteapp/data/services/news_service.dart';
import 'package:elcontrasteapp/domain/entities/push_message.dart';
import 'package:elcontrasteapp/presentation/blocs/notifications/notifications_bloc.dart';
import 'package:elcontrasteapp/presentation/pages/home/news_detail_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:audio_service/audio_service.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

import 'package:elcontrasteapp/presentation/audio/radio_player_handler.dart'; 
import 'package:elcontrasteapp/presentation/pages/home/home_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _loadEnvironment() async {
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('No se pudo cargar .env: $e');
  }
}

Future<void> _initializeLocalNotifications() async {
  try {
    await LocalNotifications.initializeLocalNotifications(
      onNotificationTap: (payload) async {
        if (payload == null || payload.isEmpty) return;

        try {
          debugPrint('Payload local notification: $payload');

          final data = jsonDecode(payload) as Map<String, dynamic>;

          if (data['type'] == 'news') {
            final postId = int.tryParse(data['post_id']?.toString() ?? '');

            if (postId != null) {
              await _openNewsFromPostId(postId);
            }
          }
        } catch (e) {
          debugPrint('Error leyendo payload de notificacion local: $e');
        }
      },
    );
  } catch (e) {
    debugPrint('No se pudieron inicializar las notificaciones locales: $e');
  }
}

Future<RadioPlayerHandler> _initializeAudioHandler() async {
  try {
    return await AudioService.init(
      builder: () => RadioPlayerHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.elcontrasteapp.radio.channel',
        androidNotificationChannelName: 'El Contraste Radio',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
        preloadArtwork: true,
        androidNotificationIcon: 'drawable/ic_notification',
      ),
    );
  } catch (e) {
    debugPrint('No se pudo inicializar AudioService: $e');
    return RadioPlayerHandler();
  }
}

Future<void> _openNewsFromPostId(int postId) async {
  try {
    final post = await NewsService().fetchPostById(postId);

    await Future.delayed(const Duration(milliseconds: 300));

    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => NewsDetailPage(post: post)),
    );
  } catch (e) {
    debugPrint('Error cargando noticia: $e');
  }
}

Future<void> _handleMessageNavigation(RemoteMessage message) async {
  final data = message.data;

  if (data['type'] == 'news') {
    final postId = int.tryParse(data['post_id'] ?? '');
    if (postId != null) {
      await _openNewsFromPostId(postId);
    }
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await NotificationsBloc.initializeFCM();
  await _initializeLocalNotifications();
  await _loadEnvironment();

  final audioHandler = await _initializeAudioHandler();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => NotificationsBloc(
            requestLocalNotificationPermission:
                LocalNotifications.requestPermissionLocalNotifications,
            showLocalNotification: LocalNotifications.showLocalNotification,
          ),
        ),
      ],
      child: ChangeNotifierProvider<RadioPlayerHandler>(
        create: (_) => audioHandler,
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
      navigatorKey: navigatorKey,
      title: 'El Contraste App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
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
  PushMessage? _lastNotification;

  @override
  void initState() {
    super.initState();
    _setupInteractedMessage();
  }

  Future<void> _setupInteractedMessage() async {
    RemoteMessage? initialMessage = await FirebaseMessaging.instance
        .getInitialMessage();

    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  void _handleMessage(RemoteMessage message) {
    context.read<NotificationsBloc>().handleRemoteMessage(
      message,
      showLocal: false,
    );
    _handleMessageNavigation(message);
  }

  void _showForegroundBanner(
    PushMessage notification,
    Map<String, dynamic> data,
  ) {
    if (!mounted) return;

    final isNews = data['type'] == 'news';
    final postId = int.tryParse(data['post_id'] ?? '');

    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              notification.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
            if (notification.body.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                notification.body,
                style: const TextStyle(fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        backgroundColor: AppColors.navyCard,
        leading: const Icon(Icons.notifications_active, color: Colors.white),
        contentTextStyle: const TextStyle(color: Colors.white),
        actions: [
          if (isNews && postId != null)
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
                _openNewsFromPostId(postId);
              },
              child: const Text(
                'VER NOTICIA',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
            },
            child: Text('CERRAR', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<NotificationsBloc, NotificationsState>(
      listener: (context, state) {
        if (state.notifications.isNotEmpty) {
          final latest = state.notifications.first;

          if (_lastNotification == null ||
              _lastNotification!.messageId != latest.messageId) {
            _lastNotification = latest;
            if (latest.data != null) {
              _showForegroundBanner(latest, latest.data!);
            }
          }
        }
      },
      child: widget.child,
    );
  }
}
