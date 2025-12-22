import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/auth/presentation/auth_provider.dart';

import 'features/auth/presentation/register_screen.dart';
import 'features/auth/presentation/otp_screen.dart'; // Import OTP Screen
import 'features/profile/presentation/profile_screen.dart';
import 'features/profile/presentation/edit_profile_screen.dart';

import 'features/profile/presentation/change_phone_screen.dart';
import 'features/rides/presentation/ride_history_screen.dart';
import 'features/earnings/presentation/earnings_screen.dart';
import 'features/settings/presentation/privacy_screen.dart';
import 'features/settings/presentation/terms_screen.dart';
import 'features/home/presentation/screens/announcements_screen.dart';
import 'features/support/presentation/screens/support_dashboard_screen.dart';
import 'features/support/presentation/screens/create_ticket_screen.dart';
import 'features/support/presentation/screens/support_chat_screen.dart';

import 'package:firebase_core/firebase_core.dart';
import 'core/services/background_service.dart';

import 'features/auth/presentation/pending_screen.dart';
import 'features/auth/presentation/permissions/location_permission_screen.dart';
import 'features/auth/presentation/permissions/notification_permission_screen.dart';
import 'features/auth/presentation/permissions/background_permission_screen.dart';
import 'core/providers/onboarding_provider.dart';
import 'features/splash/presentation/splash_screen.dart';


import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart'; // Optional if we use int consts
import 'dart:io';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
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

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  await EasyLocalization.ensureInitialized();
  await BackgroundService.initializeService();
  
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('tr'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('tr'),
      startLocale: const Locale('tr'),
      child: const ProviderScope(child: DriverApp()),
    ),
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final listenable = ValueNotifier<bool>(true);

  ref.listen(authProvider, (_, __) {
     listenable.value = !listenable.value;
  });

  ref.listen(onboardingProvider, (_, __) {
     listenable.value = !listenable.value;
  });


  return GoRouter(
    refreshListenable: listenable,
    initialLocation: '/login',
    redirect: (context, state) {
      // Handle Deep Link Redirect
      if (state.uri.scheme == 'taksibudriver' || state.uri.toString().contains('taksibudriver://')) {
          return '/home';
      }

      final authState = ref.read(authProvider);

      if (authState.isLoading) return null; // Stay on "loading" (covered by splash)

      final isLoggedIn = authState.value != null;
      final isLoggingIn = state.uri.toString() == '/login';
      final isRegistering = state.uri.toString() == '/register';
      final isVerifyingOtp = state.uri.toString() == '/otp-verify';
      final isPendingScreen = state.uri.toString() == '/pending';

      if (!isLoggedIn) {
        if (isLoggingIn || isRegistering || isVerifyingOtp) return null;
        return '/login';
      }

      // Logged in check status
      final user = authState.value != null && authState.value!.containsKey('driver') 
          ? authState.value!['driver'] 
          : (authState.value!.containsKey('user') ? authState.value!['user'] : null);
          
      String? status;
      if (authState.value!['driver'] != null) {
          status = authState.value!['driver']['status'];
      } else if (authState.value!['user'] != null && authState.value!['user']['driver_status'] != null) {
          status = authState.value!['user']['driver_status'];
      }

      final onboardingState = ref.read(onboardingProvider);
      if (onboardingState.isLoading) return null;
       
      final isCompleted = onboardingState.value ?? false;
      final isPermissionLoc = state.uri.toString() == '/permission-location';
      final isPermissionBack = state.uri.toString() == '/permission-background';
      final isPermissionNotif = state.uri.toString() == '/permission-notification';
      
      if (!isCompleted) {
         if (isPermissionLoc) return null;
         if (isPermissionBack) return null;
         if (isPermissionNotif) return null;
         return '/permission-location';
      }

      if (status == 'pending') {
          if (isPendingScreen) return null;
          return '/pending';
      }

      if (isLoggingIn || isRegistering || isVerifyingOtp || isPendingScreen) return '/home';

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/otp-verify',
        builder: (context, state) {
           final phone = state.extra as String;
           return OtpScreen(phone: phone);
        },
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/pending',
        builder: (context, state) => const PendingScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/ride-history',
        builder: (context, state) => const RideHistoryScreen(),
      ),
      GoRoute(
        path: '/earnings',
        builder: (context, state) => const EarningsScreen(),
      ),
      GoRoute(
        path: '/announcements',
        builder: (context, state) => AnnouncementsScreen(type: state.uri.queryParameters['type']),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyScreen(),
      ),
      GoRoute(
        path: '/terms',
        builder: (context, state) => const TermsScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const EditProfileScreen(),
      ),
       GoRoute(
        path: '/profile/change-phone',
        builder: (context, state) => const ChangePhoneScreen(),
      ),
      GoRoute(
        path: '/support',
        builder: (context, state) => const SupportDashboardScreen(),
        routes: [
          GoRoute(
            path: 'create',
            builder: (context, state) => const CreateTicketScreen(),
          ),
          GoRoute(
            path: 'chat/:id',
            builder: (context, state) => SupportChatScreen(ticketId: int.parse(state.pathParameters['id']!)),
          ),
        ],
      ),

      GoRoute(
        path: '/permission-location',
        builder: (context, state) => const LocationPermissionScreen(),
      ),
      GoRoute(
        path: '/permission-background',
        builder: (context, state) => const BackgroundPermissionScreen(),
      ),
      GoRoute(
        path: '/permission-notification',
        builder: (context, state) => const NotificationPermissionScreen(),
      ),
    ],

  );
});

class DriverApp extends ConsumerWidget {
  const DriverApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final authState = ref.watch(authProvider);
    
    // Remove splash screen when auth is initialized
    if (!authState.isLoading) {
      FlutterNativeSplash.remove();
    }
    
    return MaterialApp.router(
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      title: 'Taksibu Sürücü',
      theme: ThemeData(
        fontFamily: 'Inter',
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A77F6),
          primary: const Color(0xFF1A77F6),
          surface: Colors.white,
        ),
        useMaterial3: true,
        
        // Page Transitions
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),

        // Modern Input Decoration Theme - Ovallikler azaltıldı
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF1F4F8), // Light Gray
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), // Reduced
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.transparent, width: 0), // Remove blue border
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1.0),
          ),
        ),

        // Modern Button Theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A77F6),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // Reduced
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Text Button Theme
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF1A77F6), // Blue Text
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            overlayColor: const Color(0xFF1A77F6).withOpacity(0.1),
          ),
        ),
        
        // AppBar Theme
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black, 
          elevation: 0,
          centerTitle: true,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
