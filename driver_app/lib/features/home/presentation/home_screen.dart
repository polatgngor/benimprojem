import 'dart:async';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import '../../../core/services/location_service.dart';
import '../../../core/services/socket_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/widgets/custom_toast.dart';
import '../../auth/data/auth_service.dart';
import 'widgets/match_processing_sheet.dart';
import 'widgets/driver_stats_sheet.dart';
import 'screens/incoming_requests_screen.dart';
import 'providers/incoming_requests_provider.dart';
import 'providers/optimistic_ride_provider.dart';
import 'widgets/passenger_info_sheet.dart';
import 'widgets/driver_drawer.dart';
import '../../rides/presentation/widgets/rating_dialog.dart';
import '../../rides/data/ride_repository.dart';
import '../../../core/services/ringtone_service.dart';
import '../../../core/services/directions_service.dart';
import '../../splash/presentation/home_loading_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver, TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Completer<GoogleMapController> _controller = Completer();
  GoogleMapController? _mapController; 
  String _driverVehicleType = 'sari'; // Default fallback

  // Missing State Variables Added
  String _refCode = '';
  bool _isOnline = false;
  LatLng _currentPosition = const LatLng(0, 0);
  Timer? _locationUpdateTimer;
  Map<String, dynamic>? _activeRide;
  bool _isLoading = true;
  bool _hasRealLocation = false;
  StreamSubscription? _positionSubscription;  


  // ...

  // Duplicate methods _syncState, _toggleOnlineStatus, _setDriverAvailable, _startLocationUpdates removed from here using multi-replace logic. 
  // We will keep the implementations that appear later in the file or merge them if needed. 
  // Looking at the file, the implementations at the bottom (lines 737+) seem to be the primary ones for _syncState.
  // However, _startLocationUpdates and others are also duplicated.
  // The implementations around line 74-128 seem to be earlier duplicates.
  // Let's remove this entire block of duplicates to favor the refined ones or keep one single version.
  
  // Actually, looking at the file content provided previously:
  // Lines 74-91: _toggleOnlineStatus
  // Lines 93-101: _setDriverAvailable
  // Lines 103-128: _startLocationUpdates
  // AND
  // Lines 283-300: _toggleOnlineStatus (Duplicate)
  // Lines 302-310: _setDriverAvailable (Duplicate)
  // Lines 254-281: _startLocationUpdates (Duplicate)
  
  // I will REMOVE the first occurrences (lines 49-128) and trust the later ones or move the best ones up.
  // Wait, _syncState at line 49 has profile fetching which is good. _syncState at 737 has ride logic.
  // I should define ONE _syncState that does both.
  
  Future<void> _syncState({bool fitBounds = true}) async {
    try {
      // 1. Fetch Profile (RefCode/VehicleType)
      if (_refCode.isEmpty || _driverVehicleType == 'sari') {
        try {
          final profile = await ref.read(authServiceProvider).getProfile();
          if (mounted) {
             setState(() {
                if (profile['user'] != null) {
                  _refCode = profile['user']['ref_code'] ?? '';
                }
                if (profile['driver'] != null) {
                  _driverVehicleType = profile['driver']['vehicle_type'] ?? 'sari';
                }
             });
          }
        } catch (_) {}
      }
      
      // 2. Fetch Active Ride
      final repository = ref.read(driverRideRepositoryProvider);
      final activeRideData = await repository.getActiveRide();
      
      if (activeRideData != null) {
        final ride = activeRideData['ride'];
        if (!_isOnline) {
             // Don't call _toggleOnlineStatus here to avoid recursion loop if it calls sync, 
             // but here we just want to set state.
             // _toggleOnlineStatus(true) Logic:
             setState(() { _isOnline = true; });
             ref.read(socketServiceProvider).emitAvailability(
                true,
                lat: _currentPosition.latitude,
                lng: _currentPosition.longitude,
                vehicleType: _driverVehicleType
             );
             _startLocationUpdates();
             WakelockPlus.enable();
        }
        setState(() {
          _activeRide = ride;
          _fetchAndDrawRoute(fitBounds: fitBounds);
        });

        if (_isOnline) {
           ref.read(socketServiceProvider).emit('driver:rejoin');
        }
      } else {
        if (_isOnline) {
           debugPrint('🔄 Sync State: No active ride, forcing Availability TRUE');
           ref.read(socketServiceProvider).emit('driver:rejoin');
           ref.read(socketServiceProvider).emitAvailability(true);
        }
      }
    } catch (e) {
      debugPrint('Error syncing driver state: $e');
    }
  }

  void _toggleOnlineStatus(bool value) {
    if (value) {
       setState(() { _isOnline = true; });
       ref.read(socketServiceProvider).emitAvailability(
          true,
          lat: _currentPosition.latitude,
          lng: _currentPosition.longitude,
          vehicleType: _driverVehicleType
       );
       _startLocationUpdates();
       WakelockPlus.enable();
    } else {
       setState(() { _isOnline = false; });
       ref.read(socketServiceProvider).emitAvailability(false);
       WakelockPlus.disable();
       _locationUpdateTimer?.cancel();
    }
  }

  void _setDriverAvailable() {
      setState(() { _isOnline = true; });
      ref.read(socketServiceProvider).emitAvailability(
          true,
          lat: _currentPosition.latitude,
          lng: _currentPosition.longitude,
          vehicleType: _driverVehicleType
      );
  }

  void _startLocationUpdates() {
     _locationUpdateTimer?.cancel();
     _locationUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
         if (!mounted) return;
         try {
             if (_isOnline || _activeRide != null) {
                  final pos = await Geolocator.getCurrentPosition();
                  if (mounted) {
                      setState(() {
                          _currentPosition = LatLng(pos.latitude, pos.longitude);
                      });
                      
                      if (_isOnline) {
                          ref.read(socketServiceProvider).emitLocationUpdate(
                              pos.latitude, 
                              pos.longitude, 
                              vehicleType: _driverVehicleType
                          );
                      }
                  }
             }
         } catch (_) {}
     });
     
     _setupSocketListeners();
  }

  
  Set<Polyline> _polylines = {};
  
  // Route Stats
  int? _routeDistanceMeters;
  int? _routeDurationSeconds;
  
  // Lazy Loading for "Heavy" widgets (Map) to prevent transition freeze
  bool _readyForHeavyContent = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // OPTIMIZED: Delay heavy content (Map) initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
       Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) setState(() => _readyForHeavyContent = true);
       });
    });
    
    _initializeLocation();
    WakelockPlus.enable();
    // Initialize Notifications
    ref.read(notificationServiceProvider).initialize();
    // Sync state on startup
    _syncState();
    
    // Check for Overlay Permission (Critical for background launch)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOverlayPermission();
    });

    // Smooth Transition Timer
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        FlutterNativeSplash.remove(); // Remove NATIVE splash now
        setState(() => _isLoading = false); // Fade out overlay
      }
    });
  } 

  final DraggableScrollableController _statsSheetController = DraggableScrollableController();
  final DraggableScrollableController _passengerInfoController = DraggableScrollableController();

  Future<void> _checkOverlayPermission() async {
    if (Theme.of(context).platform == TargetPlatform.android) {
        final status = await Permission.systemAlertWindow.status;
        if (!status.isGranted) {
           if (mounted) {
             showDialog(
               context: context,
               builder: (ctx) => AlertDialog(
                 title: const Text('İzin Gerekli'),
                 content: const Text('Arka planda kapalıyken bile çağrı geldiğinde uygulamanın açılabilmesi için "Diğer uygulamaların üzerinde gösterim" iznine ihtiyacımız var. Lütfen açılan ekranda Taksibu Sürücü uygulamasını bulup izni açınız.'),
                 actions: [
                   TextButton(
                     onPressed: () => Navigator.pop(ctx), 
                     child: const Text('Daha Sonra')
                   ),
                   ElevatedButton(
                     onPressed: () {
                       Navigator.pop(ctx);
                       Permission.systemAlertWindow.request();
                     },
                     child: const Text('İzni Ver'),
                   ),
                 ],
               ),
             );
           }
        }

        final notifStatus = await Permission.notification.status;
        if (!notifStatus.isGranted) {
           await Permission.notification.request();
        }

        final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
        if (!batteryStatus.isGranted) {
           if (mounted) {
             showDialog(
               context: context,
               builder: (ctx) => AlertDialog(
                 title: const Text('Pil Optimizasyonu'),
                 content: const Text('Uygulamanın arka planda kesintisiz çalışabilmesi ve çağrıları kaçırmamanız için "Pil Optimizasyonunu Yoksay" izni vermeniz gerekmektedir.'),
                 actions: [
                   TextButton(
                     onPressed: () => Navigator.pop(ctx), 
                     child: const Text('Daha Sonra')
                   ),
                   ElevatedButton(
                     onPressed: () {
                       Navigator.pop(ctx);
                       Permission.ignoreBatteryOptimizations.request();
                     },
                     child: const Text('İzni Ver'),
                   ),
                 ],
               ),
             );
           }
        }
    }
  }

  Future<void> _initializeLocation() async {
    try {
        final position = await ref.read(locationServiceProvider).determinePosition();
        if (mounted) {
            setState(() {
                _currentPosition = LatLng(position.latitude, position.longitude);
                _hasRealLocation = true;
            });
            final controller = await _controller.future;
            controller.animateCamera(CameraUpdate.newLatLng(_currentPosition));
            
            _startLocationUpdates();
        }
    } catch (e) {
        debugPrint('Konum alınamadı: $e');
    }
  }





  void _setDriverAvailable_REMOVED() {
      setState(() { _isOnline = true; });
      ref.read(socketServiceProvider).emitAvailability(
          true,
          lat: _currentPosition.latitude,
          lng: _currentPosition.longitude,
          vehicleType: 'sari'
      );
  }

  Future<void> _fetchAndDrawRoute({bool fitBounds = true}) async {
    if (_activeRide == null) return;
    
    try {
        LatLng? start;
        LatLng? end;
        
        final status = _activeRide!['status'];
        
        if (status == 'assigned' || status == 'driver_arrived') {
             // Route: Driver -> Passenger
             start = _currentPosition;
             end = LatLng(
                 double.parse(_activeRide!['start_lat'].toString()),
                 double.parse(_activeRide!['start_lng'].toString())
             );
        } else if (status == 'started') {
             // Route: Driver (Passenger) -> Destination
             start = _currentPosition;
             if (_activeRide!['end_lat'] != null) {
                 end = LatLng(
                     double.parse(_activeRide!['end_lat'].toString()),
                     double.parse(_activeRide!['end_lng'].toString())
                 );
             }
        }
        
        if (start != null && end != null) {
             final result = await ref.read(directionsServiceProvider).getRouteWithInfo(start, end);
             
             if (result != null && result['points'] != null) {
                 final List<LatLng> points = result['points'] as List<LatLng>;
                 
                 setState(() {
                     _polylines = {
                         Polyline(
                             polylineId: const PolylineId('route'),
                             points: points,
                             color: const Color(0xFF0865ff),
                             width: 5,
                             jointType: JointType.round,
                             startCap: Cap.roundCap,
                             endCap: Cap.roundCap,
                             geodesic: true,
                         )
                     };
                     
                     if (result['distance_meters'] != null) {
                         _routeDistanceMeters = result['distance_meters'] as int;
                     }
                     if (result['duration_seconds'] != null) {
                         _routeDurationSeconds = result['duration_seconds'] as int;
                     }
                 });
                 
                 if (fitBounds && _mapController != null && points.isNotEmpty) {
                     // Smart Zoom
                     double minLat = points.first.latitude;
                     double maxLat = points.first.latitude;
                     double minLng = points.first.longitude;
                     double maxLng = points.first.longitude;

                     for (var p in points) {
                         if (p.latitude < minLat) minLat = p.latitude;
                         if (p.latitude > maxLat) maxLat = p.latitude;
                         if (p.longitude < minLng) minLng = p.longitude;
                         if (p.longitude > maxLng) maxLng = p.longitude;
                     }
                     
                     _mapController!.animateCamera(
                         CameraUpdate.newLatLngBounds(
                             LatLngBounds(
                                 southwest: LatLng(minLat, minLng),
                                 northeast: LatLng(maxLat, maxLng)
                             ),
                             100
                         )
                     );
                 }
             }
        }
    } catch (e) {
        debugPrint('Route fetch error: $e');
    }
  }

  Set<Marker> _createMarkers() {
      Set<Marker> markers = {};
      
      if (_activeRide != null) {
          markers.add(
              Marker(
                  markerId: const MarkerId('pickup'),
                  position: LatLng(
                      double.parse(_activeRide!['start_lat'].toString()),
                      double.parse(_activeRide!['start_lng'].toString())
                  ),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                  infoWindow: InfoWindow(title: _activeRide!['start_address']),
              )
          );
          
          if (_activeRide!['end_lat'] != null) {
              markers.add(
                  Marker(
                      markerId: const MarkerId('dropoff'),
                      position: LatLng(
                          double.parse(_activeRide!['end_lat'].toString()),
                          double.parse(_activeRide!['end_lng'].toString())
                      ),
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                      infoWindow: InfoWindow(title: _activeRide!['end_address']),
                  )
              );
          }
      }
      return markers;
  }

  Future<void> _animateToLocation() async {
    try {
      final position = await ref.read(locationServiceProvider).determinePosition();
      final controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 12, 
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
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(optimisticRideProvider, (previous, next) {
      if (next.isCompleting) {
        setState(() {
          _activeRide = null;
          _polylines.clear();
          _activeRide = null;
          _polylines.clear();
        });
        debugPrint('Optimistic Completion Triggered');
        
      } else if (next.activeRide != null) {
        setState(() {
          _activeRide = next.activeRide;
          _fetchAndDrawRoute(fitBounds: true);
        });
        debugPrint('Optimistic Ride Update applied: ${next.activeRide!['status']}');
      } else if (next.activeRide == null && !next.isMatching) {
         if (_activeRide != null && previous?.activeRide != null) {
             setState(() {
               _activeRide = null;
               _polylines.clear();
               _polylines.clear();
             });
         }
      }
    });

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        if (Theme.of(context).platform == TargetPlatform.android) {
             const intent = AndroidIntent(
               action: 'android.intent.action.MAIN',
               category: 'android.intent.category.HOME',
               flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
             );
             await intent.launch();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        resizeToAvoidBottomInset: false, // PERFORMANCE FIX: Prevent Map resize when keyboard opens
        drawer: const DriverDrawer(),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                // Map Layer
                _readyForHeavyContent ? GoogleMap(
                    trafficEnabled: true,
                    mapType: MapType.normal,
                    initialCameraPosition: CameraPosition(
                      target: _currentPosition,
                      zoom: 12, // Standardized City View
                    ),
                    myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                        padding: EdgeInsets.zero, 
                        onMapCreated: (GoogleMapController controller) {
                          _controller.complete(controller);
                        },
                        markers: _createMarkers(),
                        polylines: {
                          ..._polylines,
                        },
                      ) : const SizedBox.shrink(), // Lightweight on first frame
  
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
  
                  // BRANDING LOGO (Bottom Left - Floating with Sheet)
                  AnimatedBuilder(
                    animation: Listenable.merge([_statsSheetController, _passengerInfoController]),
                    builder: (context, child) {
                      double bottomPosition = 16.0;
                      double sheetHeight = 0.0;
                      
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
                      
                      if (sheetHeight == 0) {
                        final double safeArea = MediaQuery.of(context).viewPadding.bottom;
                        double targetPixels = _activeRide != null ? 380.0 : 350.0;
                        targetPixels += safeArea;
                        sheetHeight = targetPixels;
                      }
                      
                      double minBottom = MediaQuery.of(context).viewPadding.bottom + 16;
                      bottomPosition = sheetHeight + 10;
                      if (bottomPosition < minBottom) bottomPosition = minBottom;
                      
                      return Positioned(
                        left: 16,
                        bottom: bottomPosition,
                        child: child!,
                      );
                    },
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                      child: Center(
                        child: Text(
                          'taksibu',
                          style: GoogleFonts.montserrat(
                            color: const Color(0xFF0866ff),
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1.0,
                          ),
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
                    
                    if (sheetHeight == 0) {
                        final double safeArea = MediaQuery.of(context).viewPadding.bottom;
                        double targetPixels = _activeRide != null ? 380.0 : 350.0;
                        targetPixels += safeArea;
                        sheetHeight = targetPixels; 
                    }
                    
                    double minBottom = MediaQuery.of(context).viewPadding.bottom + 16;
                    bottomPosition = sheetHeight + 16;
                    if (bottomPosition < minBottom) bottomPosition = minBottom;
                    
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
                    child: () {
                       final optimisticState = ref.watch(optimisticRideProvider);
                       
                       if (optimisticState.isMatching) {
                         return MatchProcessingSheet(
                           key: const ValueKey('match_processing_sheet'),
                         );
                       }
                       
                       if (_activeRide != null) {
                         return PassengerInfoSheet(
                            key: const ValueKey('passenger_info_sheet'),
                            rideData: _activeRide!,
                            controller: _passengerInfoController,
                            driverLocation: _currentPosition,
                            currentDistanceMeters: _routeDistanceMeters,
                            currentDurationSeconds: _routeDurationSeconds,
                          );
                       }
                       
                       return DriverStatsSheet(
                            key: const ValueKey('driver_stats_sheet'),
                            refCount: 12, 
                            refCode: _refCode,
                            controller: _statsSheetController,
                            isOnline: _isOnline,
                            onStatusChanged: _toggleOnlineStatus,
                          );
                    }(),
                  ),
                ),
  
                // Loading Overlay (Soft Transition)
                Positioned.fill(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 1500), // Slower fade
                    switchOutCurve: Curves.easeOut, // Soft curve
                    child: _isLoading 
                        ? const HomeLoadingScreen()
                        : const SizedBox.shrink(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(notificationServiceProvider).cancelAllNotifications();
      _syncState(fitBounds: false);
    } else if (state == AppLifecycleState.detached) {
      FlutterBackgroundService().invoke("stopService");
    }
  }



  void _setupSocketListeners() {
    final socket = ref.read(socketServiceProvider).socket;
    
    socket.off('request:incoming');
    socket.on('request:incoming', (data) {
      debugPrint('Driver App received request:incoming: $data');
      if (mounted) {
        debugPrint('Playing Ringtone for new request...');
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

    socket.off('request:timeout_alert');
    socket.on('request:timeout_alert', (data) {
    });

    socket.off('request:accept_failed');
    socket.on('request:accept_failed', (data) {
      if (mounted) {
        ref.read(ringtoneServiceProvider).stopRingtone();
        
        ref.read(optimisticRideProvider.notifier).clear();
        setState(() {
          _activeRide = null; 
          _polylines.clear();
        });
        
        ref.read(incomingRequestsProvider.notifier).removeRequest(data['ride_id'].toString());
        
        CustomNotificationService().show(
          context,
          'Çağrı kabul edilemedi: ${data['reason'] ?? 'Başka sürücü aldı'}',
          ToastType.error
        );
        debugPrint('Çağrı kabul edilemedi: ${data['reason'] ?? 'Bilinmeyen hata'}');
        
        _setDriverAvailable();
      }
    });

    socket.off('request:timeout');
    socket.on('request:timeout', (data) {
      if (mounted) {
        ref.read(ringtoneServiceProvider).stopRingtone();
        ref.read(incomingRequestsProvider.notifier).removeRequest(data['ride_id'].toString());
        debugPrint('Çağrı zaman aşımına uğradı.');
      }
    });

    socket.off('request:accepted_confirm');
    socket.on('request:accepted_confirm', (data) {
      if (mounted) {
        ref.read(ringtoneServiceProvider).stopRingtone();
        
        Navigator.of(context).popUntil((route) => route.isFirst);
        
        if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
          _scaffoldKey.currentState?.closeDrawer();
        }
        
        setState(() {
          _activeRide = data;
          ref.read(incomingRequestsProvider.notifier).clearRequests();
          _syncState(fitBounds: true); 
        });
      }
    });

    socket.off('ride:cancelled');
    socket.off('ride:cancelled');
    socket.on('ride:cancelled', (data) {
      if (mounted) {
        ref.read(ringtoneServiceProvider).stopRingtone();
        
        if (data['ride_id'] != null) {
           ref.read(incomingRequestsProvider.notifier).removeRequest(data['ride_id'].toString());
        }

        ref.read(optimisticRideProvider.notifier).clear();
        
        setState(() {
          _activeRide = null;
          _polylines.clear();
        });
        
        _setDriverAvailable();
        debugPrint('Yolculuk iptal edildi. (${data['reason'] ?? 'Sebep belirtilmedi'})');
      }
    });

    socket.off('start_ride_ok');
    socket.on('start_ride_ok', (data) {
      if (mounted) {
        setState(() {
          if (_activeRide != null) {
            final updatedRide = Map<String, dynamic>.from(_activeRide!);
            updatedRide['status'] = 'started';
            _activeRide = updatedRide;
            _fetchAndDrawRoute(fitBounds: true);
          }
        });


      }
    });

    socket.off('end_ride_ok');
    socket.on('request:taken', (data) {
      if (mounted) {
        ref.read(ringtoneServiceProvider).stopRingtone();
        ref.read(incomingRequestsProvider.notifier).removeRequest(data['ride_id'].toString());
        CustomNotificationService().show(
          context,
          'Çağrı başka bir sürücü tarafından kabul edildi.',
          ToastType.info
        );
      }
    });

    socket.on('request:cancelled', (data) {
      if (mounted) {
        ref.read(ringtoneServiceProvider).stopRingtone();
        ref.read(incomingRequestsProvider.notifier).removeRequest(data['ride_id'].toString());
        CustomNotificationService().show(
          context,
          'Yolcu çağrıyı iptal etti.',
          ToastType.info
        );
      }
    });

    socket.on('end_ride_ok', (data) {
      if (mounted) {
        final rideId = _activeRide?['ride_id']?.toString() ?? data['ride_id']?.toString();
        
        final passenger = _activeRide?['passenger'];
        final passengerName = passenger != null 
            ? '${passenger['first_name']} ${passenger['last_name']}' 
            : 'ride.passenger'.tr();

        setState(() {
          _activeRide = null;
          _polylines.clear();
        });

        _setDriverAvailable(); 

        debugPrint('Yolculuk tamamlandı.');
        
        if (rideId != null) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => DriverRatingDialog(rideId: rideId, passengerName: passengerName),
          ).then((_) {
             _syncState(fitBounds: false);
          });
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
         debugPrint('Müsait duruma geçilemedi: ${data['message']}');
      }
    });

    socket.off('driver:availability_updated');
    socket.on('driver:availability_updated', (data) {
      if (mounted) {
        debugPrint('Availability updated: ${data['available']}');
      }
    });

    socket.off('start_ride_failed');
    socket.on('start_ride_failed', (data) {
      if (mounted) {
        final reason = data['reason'] ?? 'unknown';
        debugPrint('Yolculuğu başlatma hatası: $reason');
      }
    });

    socket.off('end_ride_failed');
    socket.on('end_ride_failed', (data) {
      if (mounted) {
        final reason = data['reason'] ?? 'unknown';
        debugPrint('Yolculuğu sonlandırma hatası: $reason');
      }
    });
  }
}
