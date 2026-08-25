import 'dart:async';

import 'package:elcontrasteapp/config/local_notifications/local_notifications.dart';
import 'package:elcontrasteapp/core/di/service_locator.dart';
import 'package:elcontrasteapp/core/themes/app_theme.dart';
import 'package:elcontrasteapp/data/services/news_service.dart';
import 'package:elcontrasteapp/data/services/reels_service.dart';
import 'package:elcontrasteapp/domain/entities/push_message.dart';
import 'package:elcontrasteapp/presentation/blocs/notifications/notifications_bloc.dart';
import 'package:elcontrasteapp/presentation/pages/home/news_detail_page.dart';
import 'package:elcontrasteapp/presentation/pages/reels/single_reel_page.dart';
import 'package:app_links/app_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:audio_service/audio_service.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';

import 'package:elcontrasteapp/presentation/audio/radio_player_handler.dart';
import 'package:elcontrasteapp/presentation/pages/splash/splash_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Se completa cuando el splash reemplaza su pantalla por HomePage.
///
/// Los flujos que navegan "desde afuera" (deep link, notificación) deben
/// esperar esto ANTES de empujar su propia pantalla. Sin esto hay una
/// carrera real: si el deep link resuelve rápido, empuja su pantalla
/// ENCIMA del splash, y cuando el temporizador del splash dispara su
/// pushReplacement(HomePage) — que reemplaza lo que esté ARRIBA del
/// stack en ese momento, no específicamente el splash — termina
/// reemplazando la pantalla del deep link por Home, perdiéndola.
/// Esperar a que el splash termine (con un tope de seguridad) garantiza
/// el orden final del stack sin importar cuál operación async gane.
final Completer<void> _splashDone = Completer<void>();

Future<void> _waitForSplash() {
  return _splashDone.future.timeout(
    const Duration(seconds: 3),
    onTimeout: () {},
  );
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
    final post = await getIt<NewsService>().fetchPostById(postId);

    // Espera a que el splash ya haya reemplazado su pantalla por Home
    // (ver _splashDone) antes de empujar la noticia encima.
    await _waitForSplash();
    await Future.delayed(const Duration(milliseconds: 300));

    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => NewsDetailPage(post: post)),
    );
  } catch (e) {
    debugPrint('Error cargando noticia: $e');
  }
}

/// Abre un reel específico a partir de su [reelId].
/// Se usa desde el deep link elcontraste://reel/{id} (ver [_setupDeepLinks])
/// y podría reutilizarse desde una notificación push de tipo "reel".
Future<void> _openReelFromId(String reelId) async {
  try {
    final reel = await getIt<ReelsService>().fetchReelById(reelId);

    // Espera a que el splash ya haya reemplazado su pantalla por Home
    // (ver _splashDone) antes de empujar el reel encima.
    await _waitForSplash();
    await Future.delayed(const Duration(milliseconds: 300));

    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => SingleReelPage(reel: reel)),
    );
  } catch (e) {
    debugPrint('Error cargando reel desde deep link: $e');
  }
}

/// Escucha los deep links entrantes con esquema elcontraste://reel/{id}
/// tanto si la app se abre DESDE el link (getInitialLink) como si ya
/// está corriendo y el link llega mientras tanto (uriLinkStream).
void _setupDeepLinks() {
  final appLinks = AppLinks();

  void handleUri(Uri uri) {
    debugPrint('Deep link recibido: $uri');

    // Esperamos elcontraste://reel/{id} → host = "reel", primer segmento = id
    if (uri.scheme == 'elcontraste' && uri.host == 'reel') {
      final id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
      if (id != null && id.isNotEmpty) {
        _openReelFromId(id);
      }
    }
  }

  // Link con el que se abrió la app (app cerrada)
  appLinks.getInitialLink().then((uri) {
    if (uri != null) handleUri(uri);
  });

  // Links que llegan mientras la app ya está abierta
  appLinks.uriLinkStream.listen(handleUri);
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
  await Hive.initFlutter();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  setupServiceLocator();

  await NotificationsBloc.initializeFCM();
  await _initializeLocalNotifications();

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
      home: SplashScreen(
        onNavigatedToHome: () {
          if (!_splashDone.isCompleted) _splashDone.complete();
        },
      ),
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
    _setupDeepLinks();
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
