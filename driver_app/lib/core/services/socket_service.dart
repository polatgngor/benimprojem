import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';

final socketServiceProvider = Provider<SocketService>((ref) {
  return SocketService(const FlutterSecureStorage());
});

class SocketService {
  late IO.Socket _socket;
  bool _initialized = false;
  final FlutterSecureStorage _storage;
  // Queue to hold listeners registered before socket init
  final List<Map<String, dynamic>> _pendingListeners = [];

  SocketService(this._storage);

  Future<void> connect() async {
    // If already connected, do nothing
    if (isSocketConnected) return;

    final token = await _storage.read(key: 'accessToken');
    debugPrint('Socket connecting with token: ${token?.substring(0, 10)}...');
    
    // If socket exists but disconnected, try to reconnect
    try {
      if (_socket.disconnected) {
        _socket.io.options?['extraHeaders'] = {'Authorization': 'Bearer $token'};
        _socket.io.options?['auth'] = {'token': token};
        _socket.connect();
        return;
      }
    } catch (_) {
      // _socket might be uninitialized
    }

    _socket = IO.io(AppConstants.baseUrl, IO.OptionBuilder()
        .setTransports(['websocket'])
        .setAuth({'token': token})
        .setExtraHeaders({'Authorization': 'Bearer $token'})
        .enableAutoConnect()
        .build());



    _initialized = true;
    
    // Register pending listeners
    for (final listener in _pendingListeners) {
      _socket.on(listener['event'], listener['handler']);
    }
    _pendingListeners.clear();

    _setupListeners();
  }

  void _setupListeners() {
    _socket.onConnect((_) {
      debugPrint('Socket connected: ${_socket.id}');
      _socket.emit('driver:rejoin', {});
    });

    _socket.onDisconnect((_) {
      debugPrint('Socket disconnected');
    });

    _socket.onConnectError((data) {
      debugPrint('Socket connection error: $data');
    });

    _socket.on('error', (data) {
      debugPrint('Socket error: $data');
    });
  }

  void emitAvailability(bool isAvailable, {double? lat, double? lng, String? vehicleType}) {
    if (isSocketConnected) {
      _emitAvailabilityInternal(isAvailable, lat, lng, vehicleType);
    } else {
      // Wait for connection then emit
      _socket.once('connect', (_) {
        _emitAvailabilityInternal(isAvailable, lat, lng, vehicleType);
      });
      // Ensure we are trying to connect
      connect(); 
    }
  }

  void _emitAvailabilityInternal(bool isAvailable, double? lat, double? lng, String? vehicleType) {
    debugPrint('Emitting availability: $isAvailable');
    if (!isAvailable) {
       debugPrint('Stack trace for availability false: ${StackTrace.current}');
    }
    _socket.emit('driver:set_availability', {
      'available': isAvailable,
      'lat': lat,
      'lng': lng,
      'vehicle_type': vehicleType ?? 'sari',
    });
  }

  void emitLocationUpdate(double lat, double lng, {String? vehicleType}) {
    if (isSocketConnected) {
      _socket.emit('driver:update_location', {
        'lat': lat,
        'lng': lng,
        'vehicle_type': vehicleType ?? 'sari',
      });
    }
  }

  void emitEndRide({required String rideId, required double fareActual}) {
    if (isSocketConnected) {
      _socket.emit('driver:end_ride', {
        'ride_id': rideId,
        'fare_actual': fareActual,
      });
    }
  }

  void emitCancelRide({required String rideId, required String reason}) {
    if (isSocketConnected) {
      _socket.emit('driver:cancel_ride', {
        'ride_id': rideId,
        'reason': reason,
      });
    }
  }


  void emit(String event, [dynamic data]) {
    if (isSocketConnected) {
      _socket.emit(event, data);
    }
  }

  void on(String event, Function(dynamic) handler) {
    if (_initialized) {
       // If initialized (even if disconnected), register via socket logic
       // If disconnected, socket.io client usually queues it or handles it on reconnect
       _socket.on(event, handler);
    } else {
       // Queue it for later
       _pendingListeners.add({'event': event, 'handler': handler});
    }
  }

  void off(String event, [dynamic handler]) {
    if (_initialized) {
      try {
        _socket.off(event, handler);
      } catch (_) {}
    }
  }

  void disconnect() {
    if (isSocketConnected) {
      _socket.disconnect();
    }
  }
  
  IO.Socket get socket => _socket;
  
  bool get isSocketConnected {
    try {
      return _socket.connected;
    } catch (_) {
      return false;
    }
  }
}
