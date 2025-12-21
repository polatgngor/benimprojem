import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../../core/constants/app_constants.dart';

final socketServiceProvider = Provider<SocketService>((ref) {
  return SocketService();
});

class SocketService {
  IO.Socket? _socket;

  IO.Socket get socket => _socket!;

  void init(String token) {
    if (_socket != null && _socket!.connected) return;

    _socket = IO.io(
      AppConstants.baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('Socket connected: ${_socket!.id}');
      _socket!.emit('passenger:rejoin', {});
    });

    _socket!.onConnectError((data) => debugPrint('Socket connect error: $data'));
    _socket!.onDisconnect((_) => debugPrint('Socket disconnected'));
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }

  void on(String event, Function(dynamic) callback) {
    if (_socket == null) {
      debugPrint('SocketService: Warning - trying to register listener for $event but socket is null');
      return;
    }
    debugPrint('SocketService: Registering listener for $event');
    _socket?.on(event, callback);
  }

  void off(String event) {
    _socket?.off(event);
  }

  void emit(String event, dynamic data) {
    _socket?.emit(event, data);
  }
  
  bool get isConnected => _socket?.connected ?? false;
}
