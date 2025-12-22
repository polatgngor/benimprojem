import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BackgroundPermissionScreen extends ConsumerStatefulWidget {
  const BackgroundPermissionScreen({super.key});

  @override
  ConsumerState<BackgroundPermissionScreen> createState() => _BackgroundPermissionScreenState();
}

class _BackgroundPermissionScreenState extends ConsumerState<BackgroundPermissionScreen> with WidgetsBindingObserver {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
    // System Alert Window (Overlay) check is platform specific, usually separate.
    // permission_handler 'systemAlertWindow'
    final overlayStatus = await Permission.systemAlertWindow.status;

    if (batteryStatus.isGranted && overlayStatus.isGranted) {
      if (mounted) {
        context.go('/permission-notification');
      }
    }
  }

  Future<void> _requestPermissions() async {
    setState(() => _isLoading = true);

    // 1. Battery Optimization
    if (!await Permission.ignoreBatteryOptimizations.isGranted) {
       await Permission.ignoreBatteryOptimizations.request();
    }

    // 2. Overlay (System Alert Window)
    if (!await Permission.systemAlertWindow.isGranted) {
       await Permission.systemAlertWindow.request();
    }

    setState(() => _isLoading = false);
    _checkPermissions();
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
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.battery_alert_rounded,
                  size: 64,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Arkaplan İzinleri',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Çağrıları kaçırmamanız için uygulamanın arkaplanda kesintisiz çalışması ve kilit ekranında görünebilmesi gerekir.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Bullet points
              _buildBullet('Pil Optimizasyonunu Kapat'),
              _buildBullet('Diğer Uygulamaların Üzerinde Göster'),
              
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _requestPermissions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
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
                      : const Text('İzinleri Ver'),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                   context.go('/permission-notification');
                },
                child: const Text('Şimdilik Geç', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
