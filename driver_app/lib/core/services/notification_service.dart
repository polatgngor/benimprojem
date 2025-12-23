import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../features/auth/data/auth_service.dart';

final notificationServiceProvider = Provider((ref) => NotificationService(ref));

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

    // Initialize Local Notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await _localNotifications.initialize(initializationSettings);

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
      
      // Get Token
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
        // Send to backend
        try {
          await _ref.read(authServiceProvider).updateDeviceToken(token);
        } catch (e) {
          debugPrint('Error updating device token: $e');
        }
      }

      // Foreground Message Handler
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground!');
        debugPrint('Message data: ${message.data}');

        // BLOCK Incoming Request Notification (Handled by WakeUpReceiver / Full Screen Intent)
        if (message.data['type'] == 'request_incoming') {
           debugPrint('Blocked notification for request_incoming (Silent WakeUp)');
           return;
        }

        if (message.notification != null) {
          _showLocalNotification(message);
        }
      });
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    // Use a General Channel for all other notifications (Chat, Cancel, Info)
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'general_notification_channel', // id
      'General Notifications', // title
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      // No custom sound (uses default system notification sound)
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
