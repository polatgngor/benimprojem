import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 120,
              width: 120,
              decoration: const BoxDecoration(
                 color: Colors.white,
                 shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(20),
              child: Image.asset(
                'assets/images/splash_logo.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 32),
            CircularProgressIndicator(
              color: primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
