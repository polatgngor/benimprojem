import 'dart:async';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart'; // Optional if we use int consts
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

@pragma('vm:entry-point')
class BackgroundService {
  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();
    // ... existing initialization ...
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
        autoStart: true, // Changing to true to ensure sticky behavior
        isForegroundMode: true,
        notificationChannelId: 'my_foreground',
        initialNotificationTitle: 'Taksibu Sürücü',
        initialNotificationContent: 'Arka planda konum güncelleniyor',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
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
      
      // Load Token Persistence
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      debugPrint('Background Service: Loaded token: ${token != null ? "YES" : "NO"}');

      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();

      // Initialize Socket with Token if available
      final optionsBuilder = io.OptionBuilder()
            .setTransports(['websocket'])
            .setReconnectionAttempts(double.infinity)
            .setReconnectionDelay(2000)
            .enableAutoConnect();
      
      if (token != null) {
          optionsBuilder.setExtraHeaders({'Authorization': 'Bearer $token'});
          optionsBuilder.setAuth({'token': token});
      }

      io.Socket socket = io.io(
        AppConstants.apiUrl,
        optionsBuilder.build(),
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
      //
      // SOCKET EVENT LISTENERS
      //
      final audioPlayer = AudioPlayer();

      // Ensure duplicate listeners are removed first if any (though this is onStart)
      
      socket.on('request:incoming', (data) async {
         debugPrint('Background Service received request:incoming. Launching app...');
         
         // 1. Play Ringtone IMMEDIATELY (Background Isolate)
         try {
            // Increase volume and set context
            await audioPlayer.setVolume(1.0);
            await audioPlayer.setReleaseMode(ReleaseMode.loop);
            await audioPlayer.setAudioContext(AudioContext(
              android: AudioContextAndroid(
                 isSpeakerphoneOn: true,
                 stayAwake: true,
                 contentType: AndroidContentType.music,
                 usageType: AndroidUsageType.notificationRingtone,
                 audioFocus: AndroidAudioFocus.gainTransientMayDuck,
              ),
              iOS: AudioContextIOS(
                 category: AVAudioSessionCategory.playback,
                 options: {AVAudioSessionOptions.duckOthers, AVAudioSessionOptions.mixWithOthers}, 
              ),
            ));
            await audioPlayer.play(AssetSource('sounds/ringtone.mp3'));
         } catch (e) {
            debugPrint('Background audio error: $e');
         }

         // 2. Show Full Screen Notification (Heads-up)
         try {
             // Android 10+ Restriction bypass: Use Full Screen Intent Notification
             const AndroidNotificationDetails androidPlatformChannelSpecifics =
                AndroidNotificationDetails(
                    'incoming_request_channel', 
                    'Gelen Çağrılar', // Renamed for clarity
                    channelDescription: 'Notifications for incoming ride requests',
                    importance: Importance.max,
                    priority: Priority.high,
                    ticker: 'Yeni Çağrı',
                    fullScreenIntent: true, // This is the magic key
                    category: AndroidNotificationCategory.call,
                    visibility: NotificationVisibility.public,
                    playSound: true, // System sound backup
                    enableVibration: true,
                );
            
            const NotificationDetails platformChannelSpecifics =
                NotificationDetails(android: androidPlatformChannelSpecifics);

            await flutterLocalNotificationsPlugin.show(
                888, // Unique ID for call
                'Yeni Yolculuk Çağrısı',
                'Müşteri bekliyor, kabul etmek için dokun!',
                platformChannelSpecifics,
                payload: 'taksibudriver://open' // Redirect to open
            );
         } catch (e) {
             debugPrint('Notification show failed: $e');
         }

          // 3. Force Launch App (Explicit Intent)
          if (Platform.isAndroid) {
             try {
               debugPrint('Launching via AndroidIntent with FLAG_ACTIVITY_NEW_TASK...');
               const intent = AndroidIntent(
                  action: 'android.intent.action.VIEW',
                  data: 'taksibudriver://open',
                  package: 'com.taksibu.driver.driver_app',
                  componentName: 'com.taksibu.driver.driver_app.MainActivity',
                  flags: <int>[
                    0x10000000, // FLAG_ACTIVITY_NEW_TASK
                    0x20000000, // FLAG_ACTIVITY_SINGLE_TOP
                    0x00020000, // FLAG_ACTIVITY_REORDER_TO_FRONT
                  ], 
               );
               await intent.launch();
             } catch (e) {
                debugPrint('Intent launch failed: $e');
             }
          }
      });

      // Stop ringing listeners
      void stopRinging() {
         try {
           audioPlayer.stop();
         } catch (_) {}
      }

      socket.on('request:timeout', (_) => stopRinging());
      socket.on('request:accept_failed', (_) => stopRinging());
      socket.on('request:accepted_confirm', (_) => stopRinging());
      socket.on('ride:cancelled', (_) => stopRinging());

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
           prefs.setString('auth_token', token); // Persist Token
           
           socket.io.options?['extraHeaders'] = {'Authorization': 'Bearer $token'};
           socket.io.options?['auth'] = {'token': token};
           socket.disconnect().connect();
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
