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
import 'package:wakelock_plus/wakelock_plus.dart';
import '../constants/app_constants.dart';

@pragma('vm:entry-point')
class BackgroundService {
  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();
    // ... existing initialization ...
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'my_foreground', // id
      'Taksibu Sürücü Servisi', // title
      description: 'Arkaplan servis bildirim kanalı', // description
      importance: Importance.low, // Keep low for persistent service notification (user won't be annoyed)
    );

    const AndroidNotificationChannel highImportanceChannel = AndroidNotificationChannel(
      'incoming_request_channel',
      'Gelen Çağrılar',
      description: 'Yeni yolculuk çağrıları için kullanılır',
      importance: Importance.max, // Crucial for Heads-up
      playSound: true,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
        
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(highImportanceChannel); // Register High Importance Channel

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false, // Manual start only (controlled by Online/Offline switch)
        isForegroundMode: true,
        notificationChannelId: 'my_foreground',
        initialNotificationTitle: 'Taksibu Sürücü',
        initialNotificationContent: 'Müsait',
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
      
      // Prevent CPU from sleeping
      await WakelockPlus.enable();
      
      // Load Token Persistence
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      debugPrint('Background Service: Loaded token: ${token != null ? "YES" : "NO"}');

      // Re-add plugin initialization (Fixed: previously undefined)
      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();

      // FORCE NOTIFICATION IMMEDIATELY to verify service is alive
      if (service is AndroidServiceInstance) {
          service.setAsForegroundService();
          service.setForegroundNotificationInfo(
            title: "Taksibu Sürücü",
            content: "Müsait",
          );
      }

      // Initialize Socket with Token if available
      // AGGRESSIVE RECONNECTION STRATEGY
      final optionsBuilder = io.OptionBuilder()
            .setTransports(['websocket'])
            .setReconnectionAttempts(double.infinity) // Infinite attempts
            .setReconnectionDelay(1000) // Fast retry (1s)
            .setReconnectionDelayMax(5000) // Max wait 5s
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
        debugPrint('Background Service: Socket Connected to ${AppConstants.apiUrl}');
        socket.emit('driver:rejoin', {});
        // Ensure we are marked as available in the background
        socket.emit('driver:set_availability', {
          'available': true,
          'vehicle_type': 'sari', // Default, or pass via 'configure'
        });
        
        // Update notification to show "Connected"
        if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(
            title: "Taksibu Sürücü",
            content: "Müsait",
          );
        }
      });
      
      socket.onDisconnect((_) {
         debugPrint('Background Service: Socket Disconnected. Reconnecting...');
         if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(
            title: "Taksibu Sürücü",
            content: "Bağlantı koptu - Yeniden bağlanılıyor...",
          );
        }
      });

      // Listen for incoming requests to wake up app
      //
      // SOCKET EVENT LISTENERS
      //
      final audioPlayer = AudioPlayer();

      // Ensure duplicate listeners are removed first if any (though this is onStart)
      
      socket.on('request:incoming', (data) async {
         debugPrint('Background Service received request:incoming. Executing IMMEDIATE LAUNCH sequence...');

         // 1. ACTION: FORCE SCREEN OPEN (Priority #1)
         // Fire & Forget - Do not wait for this to complete
         if (Platform.isAndroid) {
            try {
               // STRATEGY A: Native Receiver (CallStyle Notification + FullScreenIntent)
               const AndroidIntent broadcastIntent = AndroidIntent(
                  action: 'com.taksibu.driver.WAKE_UP',
                  package: 'com.taksibu.driver.driver_app',
                  componentName: 'com.taksibu.driver.driver_app.WakeUpReceiver', 
               );
               await broadcastIntent.sendBroadcast();
               debugPrint('Broadcast sent to WakeUpReceiver');
               
               // STRATEGY B: Direct Launcher Intent (Brute Force - if permission allowed)
               const AndroidIntent directIntent = AndroidIntent(
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
               directIntent.launch().catchError((e) => debugPrint('Direct Launch error: $e'));
            } catch (e) {
               debugPrint('Intent creation/sending failed: $e');
            }
         }

         // 2. ACTION: PLAY SOUND (Priority #2)
         // Fire & Forget
         try {
            audioPlayer.setVolume(1.0);
            audioPlayer.setReleaseMode(ReleaseMode.loop);
            audioPlayer.setAudioContext(AudioContext(
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
            audioPlayer.play(AssetSource('sounds/ringtone.mp3')).catchError((e) => debugPrint('Audio play error: $e'));
         } catch (e) {
            debugPrint('Audio setup failed: $e');
         }

         // 3. ACTION: SHOW NOTIFICATION (Priority #3)
         // Fire & Forget
         // On Android, the WakeUpReceiver handles the notification with FullScreenIntent.
         // On iOS, we use the local notification plugin as usual.
         if (!Platform.isAndroid) {
            try {
                const AndroidNotificationDetails androidPlatformChannelSpecifics =
                    AndroidNotificationDetails(
                        'incoming_request_channel', 
                        'Gelen Çağrılar',
                        channelDescription: 'Notifications for incoming ride requests',
                        importance: Importance.max,
                        priority: Priority.high,
                        ticker: 'Yeni Çağrı',
                        fullScreenIntent: true,
                        category: AndroidNotificationCategory.call,
                        visibility: NotificationVisibility.public,
                        playSound: true,
                        enableVibration: true,
                    );
                
                const NotificationDetails platformChannelSpecifics =
                    NotificationDetails(android: androidPlatformChannelSpecifics);

                flutterLocalNotificationsPlugin.show(
                    888,
                    'Yeni Yolculuk Çağrısı',
                    'Müşteri bekliyor, kabul etmek için dokun!',
                    platformChannelSpecifics,
                    payload: 'taksibudriver://open'
                ).catchError((e) => debugPrint('Notification error: $e'));
            } catch (e) {
                debugPrint('Notification setup failed: $e');
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
        accuracy: LocationAccuracy.bestForNavigation, // Highest accuracy
        distanceFilter: 0, // Report ALL movements (Aggressive)
        forceLocationManager: true, // Use legacy location manager if fused provider is problematic in background
        intervalDuration: const Duration(seconds: 5), // More frequent updates
        // REMOVED: foregroundNotificationConfig - This conflicts with FlutterBackgroundService's own notification
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
