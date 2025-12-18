import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/socket_service.dart';
import '../../../core/services/notification_service.dart';
import '../../auth/data/auth_service.dart';
import 'widgets/driver_stats_sheet.dart';
import 'screens/incoming_requests_screen.dart';
import 'providers/incoming_requests_provider.dart';
import 'widgets/passenger_info_sheet.dart';
import 'widgets/driver_drawer.dart';
import '../../rides/presentation/widgets/rating_dialog.dart';
import '../../rides/data/ride_repository.dart';
import '../../../core/services/ringtone_service.dart';
import '../../../core/services/directions_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  final Completer<GoogleMapController> _controller = Completer();
  LatLng? _currentPosition;
  bool _isOnline = false;
  StreamSubscription<Position>? _positionSubscription;
  Map<String, dynamic>? _incomingRequest; // Although unused in snippets, keeping for safety
  Map<String, dynamic>? _activeRide; // Store active ride details
  String _refCode = ''; // Store user ref code
  
  Timer? _locationUpdateTimer;

  Set<Polyline> _polylines = {};
  
  // Route Stats
  int? _routeDistanceMeters;
  int? _routeDurationSeconds;
  DateTime? _lastRouteFetchTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeLocation();
    WakelockPlus.enable();
    // Initialize Notifications
    ref.read(notificationServiceProvider).initialize();
    // Sync state on startup
    _syncState();
  }

  final DraggableScrollableController _statsSheetController = DraggableScrollableController();
  final DraggableScrollableController _passengerInfoController = DraggableScrollableController();




  Future<void> _animateToLocation() async {
    try {
      final position = await ref.read(locationServiceProvider).determinePosition();
      final controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 10, 
        ),
      ));
    } catch (_) {}
  }

  @override
  void dispose() {
    _statsSheetController.dispose();
    _passengerInfoController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _positionSubscription?.cancel();
    _locationUpdateTimer?.cancel();
    try {
      ref.read(socketServiceProvider).disconnect();
    } catch (_) {}
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const DriverDrawer(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Map Layer
              _currentPosition == null
                  ? const Center(child: CircularProgressIndicator())
                  : GoogleMap(
                      trafficEnabled: true,
                      mapType: MapType.normal,
                      initialCameraPosition: CameraPosition(
                        target: _currentPosition!,
                        zoom: 10,
                      ),
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      padding: const EdgeInsets.only(bottom: 280, top: 100),
                      onMapCreated: (GoogleMapController controller) {
                        _controller.complete(controller);
                      },
                      markers: _createMarkers(),
                      polylines: _polylines,
                    ),

              // Menu Button (Top Left)
              Positioned(
                top: 50,
                left: 16,
                child: Builder(
                  builder: (context) => Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.menu, color: Colors.black),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                  ),
                ),
              ),

              // Custom Location Button
              AnimatedBuilder(
                animation: Listenable.merge([_statsSheetController, _passengerInfoController]),
                builder: (context, child) {
                  double bottomPosition = 16.0;
                  double sheetHeight = 0.0;
                  
                  // Calculate height based on active sheet
                  try {
                    if (_activeRide != null) {
                       if (_passengerInfoController.isAttached) {
                         sheetHeight = _passengerInfoController.size * constraints.maxHeight;
                       }
                    } else {
                       if (_statsSheetController.isAttached) {
                         sheetHeight = _statsSheetController.size * constraints.maxHeight;
                       }
                    }
                  } catch (_) {}
                  
                  // Fallback defaults if not attached yet
                  if (sheetHeight == 0) {
                    sheetHeight = (_activeRide != null ? 0.4 : 0.3) * constraints.maxHeight; 
                  }
                  
                  bottomPosition = sheetHeight + 16;
                  
                  return Positioned(
                    right: 16,
                    bottom: bottomPosition,
                    child: child!,
                  );
                },
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 4,
                  shadowColor: Colors.black26,
                  child: InkWell(
                    onTap: _animateToLocation,
                    customBorder: const CircleBorder(),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        Icons.my_location,
                        color: Theme.of(context).primaryColor,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom Sheets (Swappable)
              Positioned.fill(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (Widget child, Animation<double> animation) {
                     return SlideTransition(
                       position: Tween<Offset>(
                         begin: const Offset(0.0, 1.0),
                         end: Offset.zero,
                       ).animate(animation),
                       child: child,
                     );
                  },
                  child: _activeRide != null
                      ? PassengerInfoSheet(
                          key: const ValueKey('passenger_info_sheet'),
                          rideData: _activeRide!,
                          controller: _passengerInfoController,
                          driverLocation: _currentPosition,
                          currentDistanceMeters: _routeDistanceMeters,
                          currentDurationSeconds: _routeDurationSeconds,
                        )
                      : DriverStatsSheet(
                          key: const ValueKey('driver_stats_sheet'),
                          refCount: 12, 
                          refCode: _refCode,
                          controller: _statsSheetController,
                          isOnline: _isOnline,
                          onStatusChanged: _toggleOnlineStatus,
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncState(fitBounds: false);
    }
  }

  Future<void> _syncState({bool fitBounds = true}) async {
    try {
      // Fetch profile if refCode is empty
      if (_refCode.isEmpty) {
        try {
          final profile = await ref.read(authServiceProvider).getProfile();
          if (mounted) {
             setState(() {
                _refCode = profile['user']['ref_code'] ?? '';
             });
          }
        } catch (_) {}
      }

      // 1. Check for active ride
      final repository = ref.read(driverRideRepositoryProvider);
      final activeRideData = await repository.getActiveRide();
      
      if (activeRideData != null) {
        final ride = activeRideData['ride'];
        if (!_isOnline) {
          _toggleOnlineStatus(true);
        }
        setState(() {
          _activeRide = ride;
          _fetchAndDrawRoute(fitBounds: fitBounds);
        });


        
        if (_isOnline) {
           ref.read(socketServiceProvider).emit('driver:rejoin');
        }
      } else {
        // 2. If no active ride, we remain in our current state (Online or Offline)
        // Do NOT force offline just because there is no ride.
        if (_isOnline) {
           // We are online but have no ride -> We are searching/available
           ref.read(socketServiceProvider).emit('driver:rejoin');
           ref.read(socketServiceProvider).emitAvailability(true);
        } else {
           // We are offline, do nothing or ensure offline
           // ref.read(socketServiceProvider).emitAvailability(false);
        }
      }
    } catch (e) {
      debugPrint('Error syncing driver state: $e');
    }
  }

  void _setupSocketListeners() {
    final socket = ref.read(socketServiceProvider).socket;
    
    socket.off('request:incoming');
    socket.on('request:incoming', (data) {
      debugPrint('Driver App received request:incoming: $data');
      if (mounted) {
        ref.read(ringtoneServiceProvider).playRingtone();
        
        final requestsNotifier = ref.read(incomingRequestsProvider.notifier);
        final currentRequests = ref.read(incomingRequestsProvider);
        final wasEmpty = currentRequests.isEmpty;

        requestsNotifier.addRequest(data);

        if (wasEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const IncomingRequestsScreen(),
            ),
          ).then((_) {
            // Handle return
          });
        }
      }
    });

    socket.off('request:accept_failed');
    socket.on('request:accept_failed', (data) {
      if (mounted) {
        ref.read(ringtoneServiceProvider).stopRingtone();
        ref.read(incomingRequestsProvider.notifier).removeRequest(data['ride_id'].toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Çağrı kabul edilemedi: ${data['reason'] ?? 'Bilinmeyen hata'}')),
        );
      }
    });

    socket.off('request:timeout');
    socket.on('request:timeout', (data) {
      if (mounted) {
        ref.read(ringtoneServiceProvider).stopRingtone();
        ref.read(incomingRequestsProvider.notifier).removeRequest(data['ride_id'].toString());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Çağrı zaman aşımına uğradı.')),
        );
      }
    });

    socket.off('request:accepted_confirm');
    socket.on('request:accepted_confirm', (data) {
      if (mounted) {
        ref.read(ringtoneServiceProvider).stopRingtone();
        setState(() {
          _activeRide = data;
          ref.read(incomingRequestsProvider.notifier).clearRequests();
          _syncState(fitBounds: true); // Revert to true to trigger smart zoom
        });


      }
    });

    socket.off('ride:cancelled');
    socket.on('ride:cancelled', (data) {
      if (mounted) {
        ref.read(ringtoneServiceProvider).stopRingtone();
        setState(() {
          _activeRide = null;
          _polylines.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yolculuk iptal edildi. (${data['reason'] ?? 'Sebep belirtilmedi'})')),
        );
      }
    });

    socket.off('start_ride_ok');
    socket.on('start_ride_ok', (data) {
      if (mounted) {
        setState(() {
          if (_activeRide != null) {
            // Create a copy to ensure didUpdateWidget detects the change
            final updatedRide = Map<String, dynamic>.from(_activeRide!);
            updatedRide['status'] = 'started';
            _activeRide = updatedRide;
            _fetchAndDrawRoute(fitBounds: true);
          }
        });


      }
    });

    socket.off('end_ride_ok');
    socket.on('end_ride_ok', (data) {
      if (mounted) {
        final rideId = _activeRide?['ride_id']?.toString() ?? data['ride_id']?.toString();
        
        // Capture passenger name before clearing state
        final passenger = _activeRide?['passenger'];
        final passengerName = passenger != null 
            ? '${passenger['first_name']} ${passenger['last_name']}' 
            : 'ride.passenger'.tr();

        setState(() {
          _activeRide = null;
          _polylines.clear();
        });

        _setDriverAvailable();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yolculuk tamamlandı.')),
        );
        if (rideId != null) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => DriverRatingDialog(rideId: rideId, passengerName: passengerName),
          );
        }
      }
    });
    
    socket.off('ride:rejoined');
    socket.on('ride:rejoined', (data) async {
      if (mounted) {
        try {
          setState(() {
             _activeRide = data; 
             _fetchAndDrawRoute(fitBounds: true);
          });
  
  
        } catch (e) {
          debugPrint('Error handling ride:rejoined: $e');
        }
      }
    });

    socket.off('driver:availability_error');
    socket.on('driver:availability_error', (data) {
      if (mounted) {
        setState(() {
          _isOnline = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Müsait duruma geçilemedi.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    });

    socket.off('driver:availability_updated');
    socket.on('driver:availability_updated', (data) {
      if (mounted) {
        debugPrint('Availability updated: ${data['available']}');
        // Optional confirmation feedback
      }
    });

    socket.off('start_ride_failed');
    socket.on('start_ride_failed', (data) {
      if (mounted) {
        final reason = data['reason'] ?? 'unknown';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Yolculuğu başlatma hatası: $reason'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    socket.off('end_ride_failed');
    socket.on('end_ride_failed', (data) {
      if (mounted) {
        final reason = data['reason'] ?? 'unknown';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Yolculuğu bitirme hatası: $reason'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    socket.off('request:reject_failed');
    socket.on('request:reject_failed', (data) {
      if (mounted) {
        final reason = data['reason'] ?? 'unknown';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Çağrı reddetme hatası: $reason'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    socket.off('request:rejected_confirm');
    socket.on('request:rejected_confirm', (data) {
      if (mounted) {
        debugPrint('Request rejected confirmed: ${data['ride_id']}');
      }
    });

    socket.off('message_failed');
    socket.on('message_failed', (data) {
      if (mounted) {
        final reason = data['reason'] ?? 'unknown';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mesaj gönderilemedi: $reason')),
        );
      }
    });

    socket.off('cancel_ride_ok');
    socket.on('cancel_ride_ok', (data) {
      if (mounted) {
        setState(() {
          _activeRide = null;
          _polylines.clear();
        });

        _setDriverAvailable();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yolculuk başarıyla iptal edildi.')),
        );
      }
    });

    socket.off('cancel_ride_failed');
    socket.on('cancel_ride_failed', (data) {
      if (mounted) {
        final reason = data['reason'] ?? 'unknown';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('İptal işlemi başarısız: $reason'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  Future<void> _initializeLocation() async {
    try {
      final position = await ref.read(locationServiceProvider).determinePosition();
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
      
      final controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newLatLng(_currentPosition!));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Konum hatası: $e')),
        );
      }
    }
  }

  Future<void> _setDriverAvailable() async {
    // If user manually switched offline, don't force online.
    if (!_isOnline) {
      debugPrint('Cannot set available: Driver is manually offline');
      return;
    }

    final socketService = ref.read(socketServiceProvider);
    
    // Ensure connected
    if (!socketService.isSocketConnected) {
       debugPrint('Socket disconnected, reconnecting before setting availability...');
       await socketService.connect();
       await Future.delayed(const Duration(milliseconds: 1000));
    }

    try {
      if (_currentPosition == null) {
        debugPrint('Current position null, fetching...');
        final pos = await ref.read(locationServiceProvider).determinePosition();
        setState(() {
          _currentPosition = LatLng(pos.latitude, pos.longitude);
        });
      }

      final vehicleType = await ref.read(authServiceProvider).getVehicleType();
      
      // Force emit availability
      socketService.emitAvailability(
        true,
        lat: _currentPosition!.latitude,
        lng: _currentPosition!.longitude,
        vehicleType: vehicleType,
      );
      
      debugPrint('Driver availability FORCE reset. Lat: ${_currentPosition!.latitude}');
      


    } catch (e) {
      debugPrint('Error setting availability: $e');
    }
  }

  void _toggleOnlineStatus(bool value) async {
    final socketService = ref.read(socketServiceProvider);
    final locationService = ref.read(locationServiceProvider);
    final authService = ref.read(authServiceProvider);

    setState(() {
      _isOnline = value;
    });

    if (_isOnline) {
      // Go Online
      await socketService.connect();
      _setupSocketListeners();
      
      final service = FlutterBackgroundService();
      final token = await authService.getToken();
      if (token != null) {
        service.invoke("setToken", {"token": token});
      }
      service.invoke("setAsForeground");
      
      final vehicleType = await authService.getVehicleType();
      final position = await locationService.determinePosition();
      
      socketService.emitAvailability(true, lat: position.latitude, lng: position.longitude, vehicleType: vehicleType);
      
      _positionSubscription = locationService.getPositionStream().listen((position) {
        final latLng = LatLng(position.latitude, position.longitude);
        setState(() {
          _currentPosition = latLng;
        });
        
        // DISABLED: Auto-tracking removed to allow manual map control


        socketService.emitLocationUpdate(position.latitude, position.longitude, vehicleType: vehicleType);

        // Update Route Periodically (throttled 15s)
        if (_activeRide != null) {
          final now = DateTime.now();
          if (_lastRouteFetchTime == null || now.difference(_lastRouteFetchTime!).inSeconds > 15) {
             _fetchAndDrawRoute();
          }
        }
      });

      _locationUpdateTimer?.cancel();
      _locationUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
        if (_currentPosition != null) {
           socketService.emitLocationUpdate(_currentPosition!.latitude, _currentPosition!.longitude, vehicleType: vehicleType);
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('home.you_are_online'.tr())),
        );
      }
    } else {
      // Go Offline
      socketService.emitAvailability(false);
      await Future.delayed(const Duration(milliseconds: 500));
      
      socketService.disconnect();
      _positionSubscription?.cancel();
      _locationUpdateTimer?.cancel();
      
      FlutterBackgroundService().invoke("stopService");
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('home.you_are_offline'.tr())),
        );
      }
    }
  }

  Set<Marker> _createMarkers() {
    if (_activeRide == null) return {};

    final isStarted = _activeRide!['status'] == 'started';
    final Set<Marker> markers = {};

    if (isStarted) {
      final endLat = double.tryParse(_activeRide!['end_lat'].toString());
      final endLng = double.tryParse(_activeRide!['end_lng'].toString());
      final address = _activeRide!['end_address'] ?? _activeRide!['dropoff_address'] ?? 'Varış Noktası';

      if (endLat != null && endLng != null) {
        markers.add(Marker(
          markerId: const MarkerId('destination'),
          position: LatLng(endLat, endLng),
          infoWindow: InfoWindow(title: 'Varış', snippet: address),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ));
      }
    } else {
      final startLat = double.tryParse(_activeRide!['start_lat'].toString());
      final startLng = double.tryParse(_activeRide!['start_lng'].toString());
      final address = _activeRide!['start_address'] ?? _activeRide!['pickup_address'] ?? 'Alış Noktası';

      if (startLat != null && startLng != null) {
        markers.add(Marker(
          markerId: const MarkerId('pickup'),
          position: LatLng(startLat, startLng),
          infoWindow: InfoWindow(title: 'Yolcu', snippet: address),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ));
      }
    }

    return markers;
  }

  Future<void> _fetchAndDrawRoute({bool fitBounds = false}) async {
    if (_activeRide == null || _currentPosition == null) return;

    try {
      _lastRouteFetchTime = DateTime.now();
      LatLng start;
      LatLng end;

      final isStarted = _activeRide!['status'] == 'started';

      if (isStarted) {
        // Ride Started: Route from Driver's Current Location -> Dropoff
        final endLat = double.tryParse(_activeRide!['end_lat'].toString());
        final endLng = double.tryParse(_activeRide!['end_lng'].toString());
        
        if (endLat == null || endLng == null) return;
        start = _currentPosition!; 
        end = LatLng(endLat, endLng);
      } else {
        // Driver -> Pickup
        start = _currentPosition!;
        final pickupLat = double.tryParse(_activeRide!['start_lat'].toString());
        final pickupLng = double.tryParse(_activeRide!['start_lng'].toString());
        
        if (pickupLat == null || pickupLng == null) return;
        end = LatLng(pickupLat, pickupLng);
      }

      final routeInfo = await ref.read(directionsServiceProvider).getRouteWithInfo(start, end);
      
      if (mounted && routeInfo != null) {
        final points = routeInfo['points'] as List<LatLng>;
        final dist = routeInfo['distance_meters'] as int;
        final dur = routeInfo['duration_seconds'] as int;

        if (points.isNotEmpty) {
          setState(() {
            _polylines = {
              Polyline(
                polylineId: const PolylineId('route'),
                points: points,
                color: Colors.blue,
                width: 5,
              ),
            };
            _routeDistanceMeters = dist;
            _routeDurationSeconds = dur;
          });
          
          if (fitBounds) {
             _controller.future.then((controller) {
               // Smart Zoom: Focus on driver's current position (start of route) with pleasant zoom
               // User request: "Yaklaşsın biraz"
               controller.animateCamera(CameraUpdate.newCameraPosition(
                 CameraPosition(
                   target: points.first, 
                   zoom: 14.5,
                 ),
               ));
             });
          }
        }
      }
    } catch (e) {
      debugPrint('Error drawing route: $e');
    }
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double? x0, x1, y0, y1;
    for (LatLng latLng in list) {
      if (x0 == null) {
        x0 = x1 = latLng.latitude;
        y0 = y1 = latLng.longitude;
      } else {
        if (latLng.latitude > x1!) x1 = latLng.latitude;
        if (latLng.latitude < x0) x0 = latLng.latitude;
        if (latLng.longitude > y1!) y1 = latLng.longitude;
        if (latLng.longitude < y0!) y0 = latLng.longitude;
      }
    }
    return LatLngBounds(northeast: LatLng(x1!, y1!), southwest: LatLng(x0!, y0!));
  }
}
