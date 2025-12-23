import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../../../auth/data/vehicle_repository.dart';
import 'change_taxi_screen.dart';

// Provider to fetch pending requests
final pendingRequestsProvider = FutureProvider.autoDispose((ref) async {
  return ref.read(vehicleRepositoryProvider).getChangeRequests();
});

class VehicleManagementScreen extends ConsumerWidget {
  const VehicleManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Current User Data
    final authState = ref.watch(authProvider);
    final user = authState.value?['user']; // Assuming structure

    // Pending Requests
    final requestsAsync = ref.watch(pendingRequestsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Araç Yönetimi'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Current Vehicle Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A77F6), Color(0xFF4C94FA)], // TaxiBu Blue Gradient
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1A77F6).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.local_taxi, size: 40, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user != null ? '${user['vehicle_plate'] ?? 'Plaka Yok'}' : 'Yükleniyor...',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    user != null ? '${user['vehicle_brand'] ?? ''} ${user['vehicle_model'] ?? ''}' : '',
                    style: const TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: const Text(
                      'Aktif Araç',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Pending Request Status
            requestsAsync.when(
              data: (requests) {
                if (requests.isEmpty) return const SizedBox.shrink();
                final latest = requests.first;
                
                // Only show if pending
                if (latest['status'] != 'pending') return const SizedBox.shrink();

                return Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4E5), // Soft Orange
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                       Container(
                         padding: const EdgeInsets.all(10),
                         decoration: BoxDecoration(
                           color: Colors.orange.withOpacity(0.1),
                           shape: BoxShape.circle,
                         ),
                         child: const Icon(Icons.access_time_filled_rounded, color: Colors.orange, size: 24),
                       ),
                       const SizedBox(width: 16),
                       Expanded(
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             const Text('Onay Bekleyen Talep', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange, fontSize: 15)),
                             const SizedBox(height: 4),
                             Text('Yeni Plaka: ${latest['new_plate']}', style: TextStyle(fontSize: 13, color: Colors.orange[900])),
                           ],
                         ),
                       ),
                    ],
                  ),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (err, stack) => const SizedBox.shrink(),
            ),

            // Actions
            const Text('İşlemler', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3242))),
            const SizedBox(height: 16),

            _buildActionCard(
              context,
              icon: Icons.swap_horiz_rounded,
              title: 'Taksi Değiştir',
              subtitle: 'Başka bir taksiye geçtiyseniz buradan bildirin.',
              onTap: () {
                // If requests pending, warn user?
                if (requestsAsync.hasValue && requestsAsync.value!.any((r) => r['status'] == 'pending')) {
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(content: Text('Zaten bekleyen bir talebiniz var.')),
                   );
                   return;
                }
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChangeTaxiScreen()));
              },
            ),
            
            const SizedBox(height: 16),

            _buildActionCard(
              context,
              icon: Icons.file_present,
              title: 'Belgelerimi Güncelle',
              subtitle: 'Ruhsat, sigorta vb. süresi dolan belgeleri yenileyin.',
              onTap: () {
                 ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(content: Text('Yakında Eklenecek')),
                   );
              },
              isComingSoon: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap, bool isComingSoon = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
          boxShadow: [
             BoxShadow(
               color: const Color(0xFF1A77F6).withOpacity(0.05),
               blurRadius: 15,
               offset: const Offset(0, 5),
             ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F4F8), // Light Blue-Grey
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: const Color(0xFF1A77F6), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3242))),
                      if (isComingSoon) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
                          child: const Text('Yakında', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 13, height: 1.4)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey[300]),
          ],
        ),
      ),
    );
  }
}

