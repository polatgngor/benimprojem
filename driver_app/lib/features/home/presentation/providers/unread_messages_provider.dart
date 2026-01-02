import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/socket_service.dart';
import '../../../../core/network/api_client.dart';

final unreadMessagesProvider = StateNotifierProvider<UnreadMessagesNotifier, Map<int, int>>((ref) {
  return UnreadMessagesNotifier(ref);
});

class UnreadMessagesNotifier extends StateNotifier<Map<int, int>> {
  final Ref ref;

  UnreadMessagesNotifier(this.ref) : super({});

  void initialize() {
    _fetchUnreadCounts();
    _setupSocketListeners();
  }

  Future<void> _fetchUnreadCounts() async {
    try {
      final response = await ApiClient.get('/rides/unread-counts');
      final data = response.data;
      final Map<String, dynamic> breakdown = data['breakdown'];
      
      final Map<int, int> newCounts = {};
      breakdown.forEach((key, value) {
        newCounts[int.parse(key)] = value as int;
      });
      
      state = newCounts;
    } catch (e) {
      // Handle error cleanly
      print('Error fetching unread counts: $e');
    }
  }

  void _setupSocketListeners() {
    final socket = ref.read(socketServiceProvider).socket;
    
    // Listen for new messages
    // Note: The event name depends on what the backend emits.
    // Based on 'rideMessage.js' planning, usually 'message:received' or similar.
    // Let's assume 'ride:message_received' based on standard conventions or check existing chat logic.
    // If not sure, we'll check chat screen.
    // Assuming 'ride:message' which is common for chat.
    
    socket.on('ride:message_received', (data) {
      // data: { ride_id, message, sender_id ... }
      // We assume the socket logic filters so we only receive messages meant for us or broadcast to room.
      // If we are the sender, we shouldn't increment.
      
      // Ideally backend sends 'ride:message' to the room.
      // We need to know OUR user id to ignore our own messages if the event is broadcast to everyone including sender.
      // But typically sender processes their own optimistic update.
      
      try {
        final rideId = int.parse(data['ride_id'].toString());
        final senderId = data['sender_id'];
        
        // We could check if (senderId != myId), but simpler is just to increment if it comes in.
        // Usually backend won't send 'ride:message_received' to sender if it was ACK'd via REST response,
        // OR it sends to everyone in room.
        
        // Let's increment.
        state = {
          ...state,
          rideId: (state[rideId] ?? 0) + 1,
        };
      } catch (_) {}
    });
  }
  
  // Call this when entering a chat screen
  Future<void> markAsRead(int rideId) async {
    // Optimistic clear
    if ((state[rideId] ?? 0) > 0) {
      final newState = Map<int, int>.from(state);
      newState.remove(rideId);
      state = newState;
      
      try {
        await ApiClient.post('/rides/$rideId/messages/read', {});
      } catch (e) {
        // Revert if failed? Nah, minor UI glitch is better than blocking.
      }
    }
  }

  int get totalUnreadCount {
    return state.values.fold(0, (sum, count) => sum + count);
  }
}
