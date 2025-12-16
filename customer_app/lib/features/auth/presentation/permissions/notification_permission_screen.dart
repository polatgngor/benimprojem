import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/onboarding_provider.dart';


class NotificationPermissionScreen extends ConsumerStatefulWidget {
  const NotificationPermissionScreen({super.key});

  @override
  ConsumerState<NotificationPermissionScreen> createState() => _NotificationPermissionScreenState();
}

class _NotificationPermissionScreenState extends ConsumerState<NotificationPermissionScreen> {
  bool _isLoading = false;

  Future<void> _completeOnboarding() async {
    await ref.read(onboardingProvider.notifier).complete();
    // Router redirect will handle navigation to /home
  }


  Future<void> _requestPermission() async {
    setState(() => _isLoading = true);
    
    // Request notification permission
    final status = await Permission.notification.request();

    setState(() => _isLoading = false);

    // Whether granted or denied, we proceed to Home
    // If permanently denied, we could show dialog, but for now let's complete flow.
    if (mounted) {
      await _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_active_rounded,
                  size: 64,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Bildirim İzni',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Sürücünüz geldiğinde veya mesaj attığında anında haberdar olmak için bildirim izni vermelisiniz.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _requestPermission,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('İzin Ver'),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                   // Skip
                   await _completeOnboarding();
                },
                child: const Text('Şimdi Değil'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
