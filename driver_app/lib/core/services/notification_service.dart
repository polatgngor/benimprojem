import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");

  if (message.data['type'] == 'request_incoming') {
     // FCM is the FAIL-SAFE. If Background Service is dead, this wakes the system.
     // We use ACTION_MAIN to force the app to the front reliably.
     debugPrint("FCM Message received (type=request_incoming). Triggering FORCE LAUNCH.");
     try {
        if (Platform.isAndroid) {
            const intent = AndroidIntent(
              action: 'android.intent.action.MAIN',
              category: 'android.intent.category.LAUNCHER',
              package: 'com.taksibu.driver.driver_app',
              componentName: 'com.taksibu.driver.driver_app.MainActivity',
              flags: <int>[
                0x10000000, // FLAG_ACTIVITY_NEW_TASK
                0x20000000, // FLAG_ACTIVITY_SINGLE_TOP
                0x04000000, // FLAG_ACTIVITY_CLEAR_TOP
                0x00020000, // FLAG_ACTIVITY_REORDER_TO_FRONT
              ], 
            );
            await intent.launch();
            debugPrint("Launched from FCM (Hybrid Strategy)");
        }
     } catch (e) {
        debugPrint("FCM Launch Error: $e");
     }
  }
}

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
     await Firebase.initializeApp();
     FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

     // Initialize Local Notifications
     const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

     const InitializationSettings initializationSettings = InitializationSettings(
       android: initializationSettingsAndroid,
     );

     await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

     // Create Channel
     const AndroidNotificationChannel channel = AndroidNotificationChannel(
       'high_importance_channel', // id
       'High Importance Notifications', // title
       description: 'This channel is used for important notifications.', // description
       importance: Importance.max,
     );

     await _flutterLocalNotificationsPlugin
         .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
         ?.createNotificationChannel(channel);

     // Foreground Handler
     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        // If app is in foreground, we might NOT want to show a notification if user is active.
        // User request: "uygulamaya girdiysem o bildirimler olmasın"
        // So we do NOTHING here for now, or only show critical alerts.
        // If we want to show non-intrusive in-app messages, we use Snackbars/Toasts separately.
        debugPrint("Foreground message received: ${message.data}");
     });
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
