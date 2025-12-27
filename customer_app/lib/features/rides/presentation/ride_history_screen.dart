import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/app_constants.dart';
import 'ride_detail_screen.dart';

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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F4F8)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
               builder: (context) => RideDetailScreen(ride: ride),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
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
                              Text(
                                ride['formatted_date'] ?? '-',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
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
                      
                    // Route Info with Timeline
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Timeline Column
                          Column(
                            children: [
                              Icon(Icons.radio_button_checked, size: 16, color: Theme.of(context).primaryColor),
                              Container(width: 2, height: 32, color: Colors.grey[200]),
                              Icon(Icons.location_on, size: 16, color: Theme.of(context).primaryColor),
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
                                const SizedBox(height: 24), 
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
                          decoration: const BoxDecoration(
                            color: Color(0xFFF8F9FA),
                            border: Border(top: BorderSide(color: Color(0xFFF1F4F8))),
                          ),
                          child: Row(
                            children: [
                              ClipOval(
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  color: Colors.white,
                                  child: (ride['driver']['profile_photo'] != null && ride['driver']['profile_photo'].isNotEmpty)
                                      ? Image.network(
                                          ride['driver']['profile_photo'].startsWith('http') 
                                              ? ride['driver']['profile_photo'] 
                                              : '${AppConstants.baseUrl}/${ride['driver']['profile_photo']}',
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) =>
                                              Icon(Icons.person, size: 26, color: Colors.grey[400]),
                                        )
                                      : Icon(Icons.person, size: 26, color: Colors.grey[400]),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${ride['driver']['first_name']?[0] ?? ''}*** ${ride['driver']['last_name']?[0] ?? ''}***',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87), 
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Sarı Taksi', // Hardcoded as per request or translate 'history.yellow_taxi'.tr()
                                      style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.withOpacity(0.1)),
                                ),
                                child: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey[400]),
                              ),
                            ],
                          ),
                       ),
                    ]
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
}
