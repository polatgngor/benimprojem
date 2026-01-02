import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/socket_service.dart';
import '../../../../core/api/api_client.dart';

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
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.client.get('/rides/unread-counts');
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
    socket.on('ride:message_received', (data) {
      // data: { ride_id, message, sender_id ... }
      try {
        final rideId = int.parse(data['ride_id'].toString());
        
        // Increment
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
        final apiClient = ref.read(apiClientProvider);
        await apiClient.client.post('/rides/$rideId/messages/read', data: {});
  }

  int get totalUnreadCount {
    return state.values.fold(0, (sum, count) => sum + count);
  }
}
