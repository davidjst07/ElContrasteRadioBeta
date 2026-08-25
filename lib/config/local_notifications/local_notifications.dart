import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotifications {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> requestPermissionLocalNotifications() async {
    try {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } catch (_) {
      // Notification permissions must not block the app from opening.
    }
  }

  static Future<void> initializeLocalNotifications({
    void Function(String? payload)? onNotificationTap,
  }) async {
    const initializationSettingsAndroid = AndroidInitializationSettings(
      'ic_notification',
    );

    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        onNotificationTap?.call(response.payload);
      },
    );

    await _createNotificationChannel();
  }

  static Future<void> _createNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      'channel_id',
      'channel_name',
      description: 'channel_description',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('silbido'),
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  static void showLocalNotification({
    required int id,
    String? title,
    String? body,
    String? data,
  }) {
    const androidDetails = AndroidNotificationDetails(
      'channel_id',
      'channel_name',
      playSound: true,
      sound: RawResourceAndroidNotificationSound('silbido'),
      channelDescription: 'channel_description',
      importance: Importance.max,
      priority: Priority.high,
      // Ícono grande a color (el logo completo), visible dentro de la
      // notificación en la bandeja. El ícono pequeño de la barra de
      // estado ('ic_notification', configurado en initialize()) es
      // aparte y Android lo fuerza a blanco/transparente sin excepción.
      largeIcon: DrawableResourceAndroidBitmap('launcher_icon'),
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: data,
    );
  }
}
