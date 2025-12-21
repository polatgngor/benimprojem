import 'package:flutter_riverpod/flutter_riverpod.dart';

class IncomingRequestsNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  IncomingRequestsNotifier() : super([]);

  void addRequest(Map<String, dynamic> request) {
    // Avoid duplicates based on ride_id
    if (!state.any((r) => r['ride_id'] == request['ride_id'])) {
      state = [...state, request];
    }
  }

  void removeRequest(String rideId) {
    state = state.where((r) => r['ride_id'].toString() != rideId).toList();
  }

  void clearRequests() {
    state = [];
  }
}

final incomingRequestsProvider = StateNotifierProvider<IncomingRequestsNotifier, List<Map<String, dynamic>>>((ref) {
  return IncomingRequestsNotifier();
});
