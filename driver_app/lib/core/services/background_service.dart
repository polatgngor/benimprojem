import 'dart:async';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../constants/app_constants.dart';

@pragma('vm:entry-point')
class BackgroundService {
  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'my_foreground', // id
      'MY FOREGROUND SERVICE', // title
      description: 'This channel is used for important notifications.', // description
      importance: Importance.low,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'my_foreground',
        initialNotificationTitle: 'Taksibu Sürücü',
        initialNotificationContent: 'Arka planda konum güncelleniyor',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    try {
      DartPluginRegistrant.ensureInitialized();
      debugPrint('Background Service: onStart called');

      // Initialize Socket
      io.Socket socket = io.io(
        AppConstants.apiUrl,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .build(),
      );

      socket.connect();

      socket.onConnect((_) {
        debugPrint('Background Service: Socket Connected');
        socket.emit('driver:rejoin', {});
        // Ensure we are marked as available in the background
        socket.emit('driver:set_availability', {
          'available': true,
          'vehicle_type': 'sari', // Default, or pass via 'configure'
        });
      });

      // Listen for incoming requests to wake up app
      socket.on('request:incoming', (_) async {
         debugPrint('Background Service: Request Incoming! Waking up app...');
         try {
            // Android 10+ Restriction bypass: Use Full Screen Intent Notification
            // This is the standard "Incoming Call" behavior
            const AndroidNotificationDetails androidPlatformChannelSpecifics =
                AndroidNotificationDetails(
                    'incoming_request_channel', 
                    'Incoming Requests',
                    channelDescription: 'Notifications for incoming ride requests',
                    importance: Importance.max,
                    priority: Priority.high,
                    ticker: 'Yeni Çağrı',
                    fullScreenIntent: true, // This is the magic key
                    category: AndroidNotificationCategory.call,
                    visibility: NotificationVisibility.public,
                    sound: RawResourceAndroidNotificationSound('notification'), // Ensure sound exists or remove
                    playSound: true,
                    enableVibration: true,
                );
            
            const NotificationDetails platformChannelSpecifics =
                NotificationDetails(android: androidPlatformChannelSpecifics);

            await flutterLocalNotificationsPlugin.show(
                999, // Unique ID
                'Yeni Yolculuk Çağrısı',
                'Müşteri bekliyor, kabul etmek için dokun!',
                platformChannelSpecifics,
                payload: 'request_incoming' // Handle in main app if needed
            );

            // Backup: Try deep link as well, just in case
            final Uri url = Uri.parse('taksibudriver://open');
            if (await canLaunchUrl(url)) {
              await launchUrl(url);
            }
         } catch (e) {
           debugPrint('Failed to notify/wake app: $e');
         }
      });

      // Listen for stop command
      service.on('stopService').listen((event) {
        service.stopSelf();
      });

      // Listen for user ID to join room
      service.on('setUserId').listen((event) {
        if (event != null && event['userId'] != null) {
          final userId = event['userId'];
          debugPrint('Background Service: Joining driver room $userId');
        }
      });
      
      service.on('setToken').listen((event) {
         if (event != null && event['token'] != null) {
           final token = event['token'];
           socket.io.options?['extraHeaders'] = {'Authorization': 'Bearer $token'};
           socket.disconnect().connect(); // Reconnect with token
         }
      });

      // Location Stream
      final locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
        forceLocationManager: true, // Use legacy location manager if fused provider is problematic in background
        intervalDuration: const Duration(seconds: 10),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: "Taksibu Sürücü",
          notificationText: "Konum servisleri aktif",
          enableWakeLock: true,
        ),
      );

      final StreamSubscription<Position> positionStream = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          if (service is AndroidServiceInstance) {
            service.setForegroundNotificationInfo(
              title: "Taksibu Sürücü",
              content: "Konum: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}",
            );
          }

          debugPrint('Background Location: ${position.latitude}, ${position.longitude}');
          
          // Emit location via socket (if connected)
          if (socket.connected) {
             socket.emit('driver:update_location', {
               'lat': position.latitude,
               'lng': position.longitude,
             });
          }
        },
        onError: (e) {
          debugPrint('Background Location Error: $e');
        },
        cancelOnError: false, // Keep listening
      );
      
      debugPrint('Background Service: Setup complete');

    } catch (e, stack) {
      debugPrint('Background Service Error: $e');
      debugPrint(stack.toString());
    }
  }
}
