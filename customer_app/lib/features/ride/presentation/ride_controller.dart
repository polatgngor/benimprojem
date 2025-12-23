import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/services/socket_service.dart';
import '../data/ride_repository.dart';
import '../data/directions_service.dart';
import 'ride_state_provider.dart';
import '../../../../core/utils/globals.dart';

part 'ride_controller.g.dart';

@Riverpod(keepAlive: true)
class RideController extends _$RideController {
  
  String? _currentRideId;
  VoidCallback? _socketCleanup;

  @override
  FutureOr<void> build() async {
    // Check for active ride on startup
    try {
      final repository = ref.read(rideRepositoryProvider);
      final activeRideData = await repository.getActiveRide();
      
      if (activeRideData != null && activeRideData['ride'] != null) {
        final activeRide = activeRideData['ride'];
        final driver = activeRideData['driver'];
        
        _currentRideId = activeRide['id'].toString();
        final status = activeRide['status'];
        
        // REJOIN LOGIC: Emit 'passenger:rejoin' if we found an active ride
        final socketService = ref.read(socketServiceProvider);
        socketService.emit('passenger:rejoin', {
          'ride_id': _currentRideId,
        });

        RideStatus rideStatus = RideStatus.idle;
        bool isActiveRide = false;

        if (status == 'requested') {
          rideStatus = RideStatus.searching;
          isActiveRide = true;
        } else if (status == 'assigned') {
          rideStatus = RideStatus.driverFound;
          isActiveRide = true;
        } else if (status == 'started') {
          rideStatus = RideStatus.rideStarted;
          isActiveRide = true;
        }

        if (!isActiveRide) {
           // Status is auto_rejected, completed, cancelled, or unknown.
           // Ignore this ride.
           // Only reset if we thought we were actively searching or riding.
           final currentState = ref.read(rideProvider);
           if (currentState.status != RideStatus.idle) {
              ref.read(rideProvider.notifier).resetRide();
           }
           return;
        }
        
        // Restore state
        ref.read(rideProvider.notifier).setRideStatus(rideStatus, rideId: _currentRideId);
        
        // Restore locations if available
        LatLng? startLoc;
        LatLng? endLoc;
        
        if (activeRide['start_lat'] != null && activeRide['start_lng'] != null) {
          startLoc = LatLng(double.parse(activeRide['start_lat'].toString()), double.parse(activeRide['start_lng'].toString()));
          ref.read(rideProvider.notifier).setStartLocation(
            startLoc,
            activeRide['start_address'] ?? '',
          );
        }
        if (activeRide['end_lat'] != null && activeRide['end_lng'] != null) {
          endLoc = LatLng(double.parse(activeRide['end_lat'].toString()), double.parse(activeRide['end_lng'].toString()));
          ref.read(rideProvider.notifier).setEndLocation(
            endLoc,
            activeRide['end_address'] ?? '',
          );
        }
        
        // Restore driver info
        if (driver != null) {
          ref.read(rideProvider.notifier).setDriverInfo(
            Map<String, dynamic>.from(driver), 
            activeRide['code4'] ?? ''
          );
        }

        // Trigger route update to restore polylines
         if (startLoc != null && endLoc != null) {
           if (rideStatus == RideStatus.searching || rideStatus == RideStatus.idle) {
             await updateRoute(startLoc, endLoc);
           } else {
             final rideState = ref.read(rideProvider);
             if (rideState.startLocation == null || rideState.endLocation == null) {
                 // Do nothing
             } else {
                 await updateRoute();
             }
           }
        }
        
        _listenForRideUpdates(_currentRideId!);

      } else {
        // No active ride found on server.
        // We rely on RideStateProvider.syncState() to handle sync logic.
        // Unconditional reset here causes data loss during drafting if controller rebuilds.
      }
    } catch (e) {
      debugPrint('Error restoring ride state: $e');
    }
  }

  Future<void> createRide(BuildContext context) async {
    final rideState = ref.read(rideProvider);
    
    if (rideState.startLocation == null || rideState.endLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen başlangıç ve bitiş noktalarını seçin.')),
      );
      return;
    }

    state = const AsyncLoading();
    
    // Fetch route for visual confirmation
    await updateRoute();

    try {
      final repository = ref.read(rideRepositoryProvider);
      
      final response = await repository.createRide(
        startLat: rideState.startLocation!.latitude,
        startLng: rideState.startLocation!.longitude,
        startAddress: rideState.startAddress ?? 'Bilinmeyen Konum',
        endLat: rideState.endLocation!.latitude,
        endLng: rideState.endLocation!.longitude,
        endAddress: rideState.endAddress,
        vehicleType: rideState.vehicleType,
        paymentMethod: rideState.paymentMethod,
        options: {
          'open_taximeter': rideState.openTaximeter,
          'has_pet': rideState.hasPet,
        },
      );
      
      debugPrint('Creating ride: From ${rideState.startAddress} TO ${rideState.endAddress}');

      // Store rideId and set status to searching BEFORE setting state
      if (response['ride'] != null) {
         final rideData = response['ride'];
         _currentRideId = rideData['id'].toString();
         
         // Sync backend fare estimate
         if (rideData['fare_estimate'] != null) {
            final currentDiff = ref.read(rideProvider);
            ref.read(rideProvider.notifier).setRouteInfo(
              fare: double.tryParse(rideData['fare_estimate'].toString()) ?? 0.0,
              distance: currentDiff.distanceMeters ?? 0,
              duration: currentDiff.durationSeconds ?? 0
            );
         }

         debugPrint('Ride created with ID: $_currentRideId. Setting status to searching.');
         ref.read(rideProvider.notifier).setRideStatus(
           RideStatus.searching, 
           rideId: _currentRideId
         );
         
         // Listen for socket events
         _listenForRideUpdates(_currentRideId!);
      } else {
        debugPrint('Ride response missing ride object: $response');
      }

      // Set state to searching (not idle) - this keeps the searching UI visible
      state = const AsyncData(null);

    } catch (e, st) {
      debugPrint('Create ride error: $e');
      state = AsyncError(e, st);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }


  void _listenForRideUpdates(String rideId) {
    // Remove existing listeners if any
    _socketCleanup?.call();
    _socketCleanup = null;
    
    final socketService = ref.read(socketServiceProvider);
    
    // Cleanup function to remove listeners
    void cleanup() {
      socketService.off('ride:assigned');
      socketService.off('ride:update_location');
      socketService.off('ride:status_update');
      socketService.off('ride:started');
      socketService.off('ride:completed');
      socketService.off('ride:cancelled');
      socketService.off('verify_code_result');
      socketService.off('start_ride_failed');
      socketService.off('end_ride_failed');
      socketService.off('message_failed');
    }

    // Register cleanup on disposal
    ref.onDispose(cleanup);
    
    // Store cleanup for manual reset
    _socketCleanup = cleanup;

    // Listen for driver assignment
    socketService.on('ride:assigned', (data) async {
      debugPrint('Ride assigned: $data');
      if (!ref.mounted) return;
      
      if (data['ride_id'].toString() == rideId) {
        final driver = data['driver'] as Map<String, dynamic>;
        final code4 = data['code4'].toString();
        
        ref.read(rideProvider.notifier).setDriverInfo(driver, code4);
        
        // OPTIMISTIC UI: Show "Driver Found!" transition sheet first
        ref.read(rideProvider.notifier).setRideStatus(RideStatus.driverFoundTransition);
        
        // Wait for 3 seconds to let the user see the "Zınk" animation
        await Future.delayed(const Duration(seconds: 3));
        
        // Then switch to the actual Driver Info Sheet
        if (ref.mounted) {
           ref.read(rideProvider.notifier).setRideStatus(RideStatus.driverFound);
        }
      }
    });

    socketService.on('ride:update_location', (data) async {
      debugPrint('Driver location update: $data');
      if (!ref.mounted) return;
      
      // Ignore updates if not in a state where driver is tracked
      final currentStatus = ref.read(rideProvider).status;
      if (currentStatus != RideStatus.driverFound && currentStatus != RideStatus.rideStarted) {
        return;
      }

      final lat = double.tryParse(data['lat'].toString());
      final lng = double.tryParse(data['lng'].toString());
      
      if (lat != null && lng != null) {
        final driverLoc = LatLng(lat, lng);
        ref.read(rideProvider.notifier).setDriverLocation(driverLoc);
        
        final rideState = ref.read(rideProvider);
        
        // If ride started, update route from Driver to Destination
        if (rideState.status == RideStatus.rideStarted && rideState.endLocation != null) {
           await updateRoute(driverLoc, rideState.endLocation!, false);
        }
        // If driver assigned (but not started), update route from Driver to Pickup
        else if (rideState.status == RideStatus.driverFound && rideState.startLocation != null) {
           await updateRoute(driverLoc, rideState.startLocation!, false);
        }
      }
    });
    
    // Listen for status updates (including auto-rejection)
    socketService.on('ride:status_update', (data) {
       debugPrint('Ride status update: $data');
       if (!ref.mounted) return;

       if (data['ride_id'].toString() == rideId) {
         final status = data['status'];
         
         if (status == 'auto_rejected') {
           ref.read(rideProvider.notifier).setRideStatus(RideStatus.noDriverFound);
         } else if (status == 'accepted' || status == 'assigned') {
            ref.read(rideProvider.notifier).setRideStatus(RideStatus.driverFound);
         }
       }
    });

    socketService.on('ride:started', (data) {
      debugPrint('Ride started: $data');
      if (!ref.mounted) return;
      if (data['ride_id'].toString() == rideId) {
        ref.read(rideProvider.notifier).setRideStatus(RideStatus.rideStarted);
      }
    });

    socketService.on('ride:completed', (data) {
      debugPrint('Ride completed: $data');
      if (!ref.mounted) return;
      if (data['ride_id'].toString() == rideId) {
        stopListening();
        ref.read(rideProvider.notifier).setRideStatus(RideStatus.completed);
      }
    });

    socketService.on('ride:cancelled', (data) {
      debugPrint('Ride cancelled: $data');
      if (!ref.mounted) return;
      if (data['ride_id'].toString() == rideId) {
        stopListening();
        ref.read(rideProvider.notifier).resetRide();
        rootScaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text('Yolculuk iptal edildi: ${data['reason'] ?? ''}')),
        );
      }
    });

    // Code verification result
    socketService.on('verify_code_result', (data) {
      debugPrint('Verify code result: $data');
      if (!ref.mounted) return;
      final ok = data['ok'] == true;
      if (!ok) {
        final reason = data['reason'] ?? 'unknown';
        rootScaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text('Kod doğrulama hatası: $reason')),
        );
      }
    });

    // Start ride failed
    socketService.on('start_ride_failed', (data) {
      debugPrint('Start ride failed: $data');
      if (!ref.mounted) return;
      final reason = data['reason'] ?? 'unknown';
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Yolculuk başlatılamadı: $reason'),
          backgroundColor: Colors.red,
        ),
      );
    });

    // End ride failed
    socketService.on('end_ride_failed', (data) {
      debugPrint('End ride failed: $data');
      if (!ref.mounted) return;
      final reason = data['reason'] ?? 'unknown';
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Yolculuk bitirilemedi: $reason'),
          backgroundColor: Colors.red,
        ),
      );
    });

    // Message send failed
    socketService.on('message_failed', (data) {
      debugPrint('Message failed: $data');
      if (!ref.mounted) return;
      final reason = data['reason'] ?? 'unknown';
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Mesaj gönderilemedi: $reason')),
      );
    });

    // Polling fallback
    Future.doWhile(() async {
      try {
        if (ref.read(rideProvider).status != RideStatus.searching) return false;
      } catch (_) {
        return false;
      }
      
      await Future.delayed(const Duration(seconds: 5)); 
      
      try {
        if (ref.read(rideProvider).status != RideStatus.searching) return false;

        final repository = ref.read(rideRepositoryProvider);
        final activeRideData = await repository.getActiveRide();
        
        if (activeRideData != null) {
          final ride = activeRideData['ride'];
          final statusStr = ride['status'];
          
          if (statusStr == 'assigned') {
             final driver = activeRideData['driver'];
             if (driver != null) {
                ref.read(rideProvider.notifier).setDriverInfo(
                  Map<String, dynamic>.from(driver), 
                  ride['code4'] ?? ''
                );
                ref.read(rideProvider.notifier).setRideStatus(RideStatus.driverFound);
                return false; 
             }
          } else if (statusStr == 'started') {
             ref.read(rideProvider.notifier).setRideStatus(RideStatus.rideStarted);
             return false;
          }
        }
      } catch (e) {
        debugPrint('Polling error: $e');
      }

      return true;
    });
  }

  void stopListening() {
    _socketCleanup?.call();
    _socketCleanup = null;
  }

  Future<void> cancelRide(BuildContext context, {String? reason}) async {
    if (_currentRideId == null) return;

    try {
      final repository = ref.read(rideRepositoryProvider);
      final rideIdToCancel = _currentRideId; // Capture ID locally
      
      // OPTIMISTIC UPDATE: Clear UI immediately
      state = const AsyncData(null); 
      _currentRideId = null;
      ref.read(rideProvider.notifier).resetRide();
      stopListening();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Arama iptal edildi.')),
        );
      }

      // Fire and forget (almost)
      if (rideIdToCancel != null) {
        await repository.cancelRide(rideIdToCancel, reason: reason);
      }

    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İptal edilemedi: $e')),
        );
      }
    }
  }

  Future<void> updateRoute([LatLng? start, LatLng? end, bool updateFare = true]) async {
    final rideState = ref.read(rideProvider);
    final startLocation = start ?? rideState.startLocation;
    final endLocation = end ?? rideState.endLocation;

    if (startLocation == null || endLocation == null) return;

    try {
      final directionsService = ref.read(directionsServiceProvider);
      final routeInfo = await directionsService.getRoute(
        startLocation,
        endLocation,
      );

      if (routeInfo != null) {
        final polyline = Polyline(
          polylineId: const PolylineId('route'),
          points: routeInfo.points,
          color: Colors.blue,
          width: 5,
        );
        
        ref.read(rideProvider.notifier).setPolylines({polyline});

        if (updateFare) {
          // Fetch backend estimates
          try {
            final repository = ref.read(rideRepositoryProvider);
            final estimatesData = await repository.getFareEstimates(
              startLat: startLocation.latitude,
              startLng: startLocation.longitude,
              endLat: endLocation.latitude,
              endLng: endLocation.longitude,
            );
            
            // Map<String, dynamic> -> Map<String, double>
            final estimates = <String, double>{};
            if (estimatesData['estimates'] != null) {
              (estimatesData['estimates'] as Map<String, dynamic>).forEach((k, v) {
                estimates[k] = (v as num).toDouble();
              });
            }

            // Update state with map
            ref.read(rideProvider.notifier).setFareEstimates(estimates);
            
            // Also update the currently selected vehicle type's estimate for backward compatibility logic if needed
            final currentType = rideState.vehicleType;
            final currentFare = estimates[currentType] ?? 0.0;

            ref.read(rideProvider.notifier).setRouteInfo(
              fare: currentFare,
              distance: (estimatesData['distance_meters'] as num?)?.toInt() ?? routeInfo.distanceMeters,
              duration: (estimatesData['duration_seconds'] as num?)?.toInt() ?? routeInfo.durationSeconds,
            );
          } catch (e) {
            debugPrint('Error fetching backend estimates: $e');
            // Fallback to local calculation if backend fails? 
            // Better to show error or 0.
          }
        } else {
             ref.read(rideProvider.notifier).setRouteInfo(
                fare: rideState.fare ?? 0, 
                distance: routeInfo.distanceMeters,
                duration: routeInfo.durationSeconds,
             );
        }
      }
    } catch (e) {
      debugPrint('Error fetching route/estimates: $e');
    }
  }
}
