import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/app_constants.dart';
import 'widgets/ride_map_preview.dart';
import '../../ride/presentation/chat_screen.dart';

class RideHistoryScreen extends ConsumerStatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  ConsumerState<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends ConsumerState<RideHistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _rides = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 1;
  final int _limit = 20;

  @override
  void initState() {
    super.initState();
    _fetchRides();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _fetchRides();
    }
  }

  Future<void> _fetchRides() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.client.get('/rides', queryParameters: {
        'page': _page,
        'limit': _limit,
      });

      final data = response.data;
      if (data['rides'] != null) {
        final List<dynamic> newRides = data['rides'];
        if (newRides.length < _limit) {
          _hasMore = false;
        }
        
        setState(() {
          _rides.addAll(List<Map<String, dynamic>>.from(newRides));
          _page++;
        });
      } else {
        _hasMore = false;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('drawer.rides'.tr()),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _rides.isEmpty && _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _rides.isEmpty && !_isLoading
              ? Center(child: Text('history.no_rides'.tr(), style: TextStyle(color: Colors.grey[600])))
              : ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemCount: _rides.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _rides.length) {
                      return const Center(child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ));
                    }

                    final ride = _rides[index];
                    return _buildRideCard(ride);
                  },
                ),
    );
  }

  Widget _buildRideCard(Map<String, dynamic> ride) {
    final date = DateTime.tryParse(ride['created_at'] ?? '') ?? DateTime.now();
    final status = ride['status'];
    final fare = ride['fare_actual'] ?? ride['fare_estimated'];
    final pickup = ride['start_address'] ?? 'history.unknown'.tr();
    final dropoff = ride['end_address'] ?? 'history.unknown'.tr();
    final statusColor = _getStatusColor(status);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white, // Cleaner look than gray
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

                  // Driver Info Footer
                  if (ride['driver'] != null) ...[
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
                                child: (ride['driver']['profile_photo'] != null && ride['driver']['profile_photo'].isNotEmpty)
                                    ? Image.network(
                                        ride['driver']['profile_photo'].startsWith('http') 
                                            ? ride['driver']['profile_photo'] 
                                            : '${AppConstants.baseUrl}/${ride['driver']['profile_photo']}',
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
                                Row(
                                  children: [
                                    Text(
                                      '${ride['driver']['first_name']?[0] ?? ''}*** ${ride['driver']['last_name']?[0] ?? ''}***',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'history.yellow_taxi'.tr(),
                                      style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.normal),
                                    ),
                                  ],
                                ),
                if (ride['driver']['driver'] != null)
                                  Text(
                                    ride['driver']['driver']['vehicle_plate'] ?? '',
                                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                  ),
                              ],
                            ),
                            const Spacer(),
                            // CHAT BUTTON (If completed & < 12 hours)
                            if (status == 'completed' && _isChatAvailable(ride['updated_at'] ?? ride['created_at']))
                              ElevatedButton.icon(
                                onPressed: () {
                                  // Navigate to Chat Screen
                                  // We need to import ChatScreen, but for now assuming it is available or I will add import
                                  // Since ChatScreen is in another feature, I might need to import it.
                                  // Let's rely on relative import or manual fix if needed.
                                  // Actually, I should check dynamic import or better yet, using named routes if available?
                                  // The project seems to use direct navigation in some places.
                                  // I'll assume direct navigation for now.
                                  Navigator.push(
                                    context, 
                                    MaterialPageRoute(builder: (context) => 
                                      // Using dynamic import trick or just expecting auto-resolve? No, I must add import.
                                      // Since I cannot add import easily with just this chunk in middle of file, I will add a helper method and the button here.
                                      // Wait, I can use multi-replace to add import too.
                                      // BUT replacing chunks is safer.
                                      // Let's use a callback or just standard navigation. 
                                      // I will add import in a separate chunk.
                                      // For now, let's just put the button logic.
                                      // I will use a placeholder widget `ChatScreen(rideId: ...)` and add import at top.
                                      ChatScreen(rideId: ride['id'].toString())
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
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRouteRow(IconData icon, String text, BuildContext context) {
    // Both Start and End icons are now Blue (primary color)
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
      case 'requested': return 'history.status.requested'.tr();
      case 'assigned': return 'history.status.assigned'.tr();
      default: return status ?? '-';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'completed': return const Color(0xFF1A77F6); // Primary Blue
      case 'cancelled': return Colors.red;
      case 'started': return Colors.blueAccent;
      case 'requested': return Colors.orange;
      case 'assigned': return Colors.teal;
      default: return Colors.grey;
    }
  }

  bool _isChatAvailable(String? dateStr) {
    if (dateStr == null) return false;
    try {
      final date = DateTime.parse(dateStr); // UTC usually from DB
      // updated_at from sequelize is usually UTC. 
      // DateTime.now() is local? Or UTC? 
      // Flutter DateTime.now() is local. 
      // We should compare carefully.
      // If dateStr ends with Z, it is UTC.
      // Sequelize by default sends ISO string.
      // Let's assume standard parsing handles it.
      // Better: Convert both to UTC or Local.
      final diff = DateTime.now().difference(date.toLocal());
      return diff.inHours < 12;
    } catch (e) {
      return false;
    }
  }
}
