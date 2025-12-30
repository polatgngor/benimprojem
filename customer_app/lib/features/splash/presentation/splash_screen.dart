import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../../core/providers/onboarding_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkState();
  }

  Future<void> _checkState() async {
    // Artificial delay to prevent flickers? Not needed if just logic.
    // But helpful for smooth splash removal.
    // Let Providers initialize.
    
    // We wait for the next frame to ensure providers are ready
    await Future.delayed(Duration.zero);
    
    // Auth State is handled by router redirect usually, 
    // but here we can force decision if router is purely listening.
    // Actually, simply by existing as the initial route, the router's redirect logic 
    // (which runs on every route change) will likely kick in instantly.
    
    // However, to be cleaner, we can manually check here if redirect doesn't auto-trigger
    // or if we want a manual transition.
  }

  @override
  Widget build(BuildContext context) {
    // This UI matches the "Soft Landing" and "Login" branding
    // Ensuring visual continuity.
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/images/splash_logo_padded.png',
        ),
      ),
    );
  }
}
