import 'dart:io';

import 'package:elcontrasteapp/domain/entities/push_message.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:convert';

import '../../../firebase_options.dart';

part 'notifications_event.dart';
part 'notifications_state.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  debugPrint('Handling a background message: ${message.messageId}');
}

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final FirebaseMessaging messaging = FirebaseMessaging.instance;
  int pushNumberId = 0;

  final Future<void> Function() requestLocalNotificationPermission;
  final void Function({
    required int id,
    String? title,
    String? body,
    String? data,
  })?
  showLocalNotification;

  NotificationsBloc({
    required this.requestLocalNotificationPermission,
    this.showLocalNotification,
  }) : super(NotificationsState()) {
    on<NotificationStatusChanged>(_notificationStatusChanged);
    on<NotificationReceived>(_onPushMessageReceived);

    // Realizar la verificación inicial del estado de las notificaciones
    _initialStatusCheck();

    // Listener para notificaciones en Foreground
    _onForegroundMessage();
  }

  static Future<void> initializeFCM() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    try {
      await FirebaseMessaging.instance.subscribeToTopic('todas_las_notas');
    } catch (e) {
      debugPrint('Error suscribiendo al topic todas_las_notas: $e');
    }
  }

  void _notificationStatusChanged(
    NotificationStatusChanged event,
    Emitter<NotificationsState> emit,
  ) {
    emit(state.copyWith(status: event.status));
    _getFMCToken();
  }

  void _onPushMessageReceived(
    NotificationReceived event,
    Emitter<NotificationsState> emit,
  ) {
    emit(
      state.copyWith(
        notifications: [event.pushMessage, ...state.notifications],
      ),
    );
  }

  void _initialStatusCheck() async {
    try {
      final settings = await messaging.getNotificationSettings();
      add(NotificationStatusChanged(settings.authorizationStatus));

      if (settings.authorizationStatus == AuthorizationStatus.notDetermined ||
          settings.authorizationStatus == AuthorizationStatus.denied) {
        requestPermission();
      }
    } catch (e) {
      debugPrint('Error revisando estado de notificaciones: $e');
    }
  }

  void _getFMCToken() async {
    if (state.status != AuthorizationStatus.authorized) {
      return;
    }

    try {
      final token = await messaging.getToken();
      // Solo se imprime en desarrollo (para copiarlo y probar pushes desde
      // la consola de Firebase). El token identifica este dispositivo
      // específico — no debe quedar visible en logcat de producción.
      if (kDebugMode) {
        debugPrint('FCM Token: $token');
      }
    } catch (e) {
      debugPrint('Error obteniendo token FCM: $e');
    }
  }

  void handleRemoteMessage(RemoteMessage message, {bool showLocal = true}) {
    debugPrint('Got a message whilst in the foreground!');
    debugPrint('Message data: ${message.data}');

    String title = '';
    String? body;
    String? imageUrl;

    if (message.notification != null) {
      debugPrint(
        'Message also contained a notification: ${message.notification}',
      );
      title = message.notification!.title ?? '';
      body = message.notification!.body;
      imageUrl = Platform.isAndroid
          ? message.notification!.android?.imageUrl
          : message.notification!.apple?.imageUrl;
    }

    if (title.isEmpty) {
      title = message.data['title'] ?? 'Nueva notificación';
    }

    final notification = PushMessage(
      messageId:
          message.messageId?.replaceAll(':', '').replaceAll('%', '') ?? '',
      title: title,
      body: body ?? '',
      sentDate: message.sentTime ?? DateTime.now(),
      data: message.data,
      imageUrl: imageUrl,
    );

    if (showLocal && showLocalNotification != null) {
      showLocalNotification!(
        id: pushNumberId++,
        title: notification.title,
        body: notification.body,
        data: jsonEncode(notification.data),
      );
    }

    add(NotificationReceived(notification));
  }

  void _onForegroundMessage() {
    FirebaseMessaging.onMessage.listen(handleRemoteMessage);
  }

  void requestPermission() async {
    try {
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      await requestLocalNotificationPermission();

      add(NotificationStatusChanged(settings.authorizationStatus));
    } catch (e) {
      debugPrint('Error solicitando permisos de notificacion: $e');
    }
  }

  PushMessage? getMessageById(String pushMessageId) {
    final exist = state.notifications.any(
      (element) => element.messageId == pushMessageId,
    );
    if (!exist) return null;

    return state.notifications.firstWhere(
      (element) => element.messageId == pushMessageId,
    );
  }
}
