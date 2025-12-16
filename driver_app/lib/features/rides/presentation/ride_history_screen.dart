import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/data/auth_service.dart';
import 'widgets/ride_map_preview.dart';
import '../../home/presentation/screens/driver_chat_screen.dart';

final driverRideHistoryProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final authService = ref.read(authServiceProvider);
  final token = await authService.getToken();
  if (token == null) throw Exception('No token');
  
  final dio = Dio();
  final response = await dio.get(
    '${AppConstants.apiUrl}/rides',
    options: Options(headers: {'Authorization': 'Bearer $token'}),
  );
  final data = response.data;
  if (data['rides'] != null) {
    return List<Map<String, dynamic>>.from(data['rides']);
  }
  return [];
});

class RideHistoryScreen extends ConsumerWidget {
  const RideHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ridesAsync = ref.watch(driverRideHistoryProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('history.title'.tr()),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ridesAsync.when(
        data: (rides) {
          if (rides.isEmpty) {
            return Center(child: Text('history.no_rides'.tr(), style: TextStyle(color: Colors.grey[600])));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: rides.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final ride = rides[index];
              return _buildRideCard(context, ride);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Hata: $err')),
      ),
    );
  }

  Widget _buildRideCard(BuildContext context, Map<String, dynamic> ride) {
    final date = DateTime.tryParse(ride['created_at'] ?? '') ?? DateTime.now();
    final status = ride['status'];
    final fare = ride['fare_actual'] ?? ride['fare_estimated'];
    final pickup = ride['start_address'] ?? 'history.unknown'.tr();
    final dropoff = ride['end_address'] ?? 'history.unknown'.tr();
    final statusColor = _getStatusColor(status);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Status Accent Strip
            Container(
              width: 6,
              color: statusColor,
            ),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   // Header: Date & Price
                   Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getStatusText(status),
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ride['formatted_date'] ?? '-',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        Text(
                          fare != null ? '₺$fare' : '-',
                          style: TextStyle(
                            fontSize: 18, 
                            fontWeight: FontWeight.w800, 
                            color: Theme.of(context).primaryColor
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1, color: Colors.black12),

                   // Map Preview (if available)
                  if (ride['start_lat'] != null && ride['end_lat'] != null)
                    SizedBox(
                      height: 120,
                      child: RideMapPreview(
                        startLat: double.parse(ride['start_lat'].toString()),
                        startLng: double.parse(ride['start_lng'].toString()),
                        endLat: double.parse(ride['end_lat'].toString()),
                        endLng: double.parse(ride['end_lng'].toString()),
                      ),
                    ),
                  
                   // Route Info with Timeline
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Timeline Column
                        Column(
                          children: [
                            Icon(Icons.circle, size: 12, color: Theme.of(context).primaryColor),
                            Container(width: 2, height: 30, color: Colors.grey[300]), // Line
                            const Icon(Icons.location_on, size: 16, color: Colors.red),
                          ],
                        ),
                        const SizedBox(width: 12),
                         // Addresses
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pickup,
                                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 24), // Match line height
                              Text(
                                dropoff,
                                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                if (ride['passenger'] != null) ...[
                     Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          border: Border(top: BorderSide(color: Colors.grey[100]!)),
                        ),
                        child: Row(
                          children: [
                            ClipOval(
                              child: Container(
                                width: 28,
                                height: 28,
                                color: Colors.white,
                                child: (ride['passenger']['profile_photo'] != null && ride['passenger']['profile_photo'].isNotEmpty)
                                    ? Image.network(
                                        ride['passenger']['profile_photo'].startsWith('http') 
                                            ? ride['passenger']['profile_photo'] 
                                            : '${AppConstants.baseUrl}/${ride['passenger']['profile_photo']}',
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            const Icon(Icons.person, size: 16, color: Colors.grey),
                                      )
                                    : const Icon(Icons.person, size: 16, color: Colors.grey),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${ride['passenger']['first_name']?[0] ?? ''}*** ${ride['passenger']['last_name']?[0] ?? ''}***',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                Text(
                                  'ride.passenger'.tr(),
                                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                                ),
                              ],
                            ),
                            const Spacer(),
                            // CHAT BUTTON (If completed & < 12 hours)
                            if (status == 'completed' && _isChatAvailable(ride['updated_at'] ?? ride['created_at']))
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context, 
                                    MaterialPageRoute(builder: (context) => 
                                      DriverChatScreen(rideId: ride['id'].toString())
                                    )
                                  );
                                },
                                icon: const Icon(Icons.chat_bubble_outline, size: 16),
                                label: Text('button.chat'.tr()),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1A77F6),
                                  foregroundColor: Colors.white,
                                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  elevation: 0,
                                ),
                              )
                          ],
                        ),
                     )
                   ]
                ],
              ),
            )
          ],
        ),
      )
    );
  }
  
  Widget _buildRouteRow(IconData icon, String text, BuildContext context) {
    // Icons are now Blue (primary color)
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'completed': return 'history.status.completed'.tr();
      case 'cancelled': return 'history.status.cancelled'.tr();
      case 'started': return 'history.status.started'.tr();
      default: return status ?? '-';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'completed': return const Color(0xFF1A77F6); // Primary Blue
      case 'cancelled': return Colors.red;
      case 'started': return Colors.blueAccent;
      default: return Colors.grey;
    }
  }

  bool _isChatAvailable(String? dateStr) {
    if (dateStr == null) return false;
    try {
      final date = DateTime.parse(dateStr); 
      final diff = DateTime.now().difference(date.toLocal());
      return diff.inHours < 12;
    } catch (e) {
      return false;
    }
  }
}
