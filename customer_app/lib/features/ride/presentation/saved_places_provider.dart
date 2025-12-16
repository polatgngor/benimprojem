import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/saved_place_model.dart';
import '../data/saved_places_service.dart';

final savedPlacesProvider = AsyncNotifierProvider<SavedPlacesNotifier, List<SavedPlace>>(() {
  return SavedPlacesNotifier();
});

class SavedPlacesNotifier extends AsyncNotifier<List<SavedPlace>> {
  
  @override
  Future<List<SavedPlace>> build() async {
    final service = ref.read(savedPlacesServiceProvider);
    return service.getSavedPlaces();
  }

  Future<void> addPlace({
    required String title,
    required String address,
    required double lat,
    required double lng,
    String icon = 'place',
  }) async {
    final service = ref.read(savedPlacesServiceProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final newPlace = await service.addSavedPlace(
        title: title,
        address: address,
        lat: lat,
        lng: lng,
        icon: icon,
      );
      // Helper function to update state:
      final currentList = state.value ?? [];
      return [newPlace, ...currentList];
    });
  }

  Future<void> deletePlace(String id) async {
    final service = ref.read(savedPlacesServiceProvider);
    // Optimistic update or reload? Let's reload or filter locally.
    // Filtering locally is smoother.
    final previousState = state;
    
    // Set loading? Maybe not necessary for delete as it's quick usually, but good practice.
    // state = const AsyncValue.loading(); // Removing this to avoid flicker
    
    try {
      await service.deleteSavedPlace(id);
      
      state = AsyncValue.data(
        previousState.value?.where((p) => p.id != id).toList() ?? []
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
