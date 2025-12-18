import 'package:flutter_riverpod/flutter_riverpod.dart';

class OptimisticRideNotifier extends Notifier<Map<String, dynamic>?> {
  @override
  Map<String, dynamic>? build() => null;

  void setOptimistic(Map<String, dynamic> ride) {
    state = ride;
  }

  void updateStatus(String status) {
    if (state != null) {
      final updated = Map<String, dynamic>.from(state!);
      updated['status'] = status;
      state = updated;
    }
  }

  void clear() {
    state = null;
  }
}

final optimisticRideProvider = NotifierProvider<OptimisticRideNotifier, Map<String, dynamic>?>(OptimisticRideNotifier.new);
