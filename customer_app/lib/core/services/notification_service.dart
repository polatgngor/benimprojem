import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../features/auth/data/auth_repository.dart';

final notificationServiceProvider = Provider((ref) => NotificationService(ref));

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  final Ref _ref;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  NotificationService(this._ref);

  Future<void> initialize() async {
    // Request Permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
      
      // Initialize Local Notifications
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);
      
      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // Handle local notification tap
          // For now, just bringing app to foreground is enough as HomeScreen will sync state
          debugPrint('Notification tapped with payload: ${response.payload}');
        },
      );

      // Get Token
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
        // Send to backend
        try {
          await _ref.read(authRepositoryProvider).updateDeviceToken(token);
        } catch (e) {
          debugPrint('Error updating device token: $e');
        }
      }

      // Foreground Message Handler
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground!');
        debugPrint('Message data: ${message.data}');

        if (message.notification != null) {
          _showLocalNotification(message);
        }
      });

      // Background Message Tap Handler
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('A new onMessageOpenedApp event was published!');
        // Navigation is handled by HomeScreen syncing state on resume
      });
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      platformChannelSpecifics,
      payload: message.data['type'],
    );
  }
}
