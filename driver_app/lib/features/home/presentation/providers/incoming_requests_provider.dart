import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'incoming_requests_provider.g.dart';

@Riverpod(keepAlive: true)
class IncomingRequests extends _$IncomingRequests {
  @override
  List<Map<String, dynamic>> build() {
    return [];
  }

  void addRequest(Map<String, dynamic> request) {
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
