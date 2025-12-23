import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../data/auth_service.dart';

part 'auth_provider.g.dart';

@riverpod
class Auth extends _$Auth {
  final _storage = const FlutterSecureStorage();

  @override
  FutureOr<Map<String, dynamic>?> build() async {
    // Check if token exists
    final token = await _storage.read(key: 'accessToken');
    if (token != null) {
      try {
        final service = ref.read(authServiceProvider);
        final profile = await service.getProfile();
        return profile;
      } catch (e) {
        // If profile fetch fails (e.g. token expired), clear token
        await _storage.delete(key: 'accessToken');
        return null;
      }
    }

    // Register Push Token (Fire and Forget)
    _initPushToken();
    
    return null;
  }

  Future<void> _initPushToken() async {
    try {
      final token = await _storage.read(key: 'accessToken');
      if (token == null) return;

      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        final service = ref.read(authServiceProvider);
        await service.updateDeviceToken(fcmToken);
      }
    } catch (e) {
      // Ignore token sync errors
    }
  }

  Future<void> sendOtp(String phone) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(authServiceProvider);
      await service.sendOtp(phone);
      return state.value;
    });
  }

  /// Returns map: { is_new_user: bool, verification_token: String?, user: Map? }
  Future<Map<String, dynamic>?> verifyOtp(String phone, String code) async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(authServiceProvider);
      final data = await service.verifyOtp(phone, code);

      if (data['is_new_user'] == true) {
        state = const AsyncValue.data(null);
        return {
          'is_new_user': true,
          'verification_token': data['verification_token']
        };
      } else {
        // Login success
        state = AsyncValue.data(data);
        return {
          'is_new_user': false,
          'user': data['user']
        };
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<void> register({
    required String firstName,
    required String lastName,
    required String verificationToken,
    required String vehiclePlate,
    required String vehicleBrand,
    required String vehicleModel,
    required String vehicleType,
    String? driverCardNumber,
    String? workingRegion,
    String? workingDistrict,
    dynamic photo,
    dynamic vehicleLicense,
    dynamic ibbCard,
    dynamic drivingLicense,
    dynamic identityCard,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(authServiceProvider);
      final data = await service.register(
        firstName: firstName,
        lastName: lastName,
        verificationToken: verificationToken,
        vehiclePlate: vehiclePlate,
        vehicleBrand: vehicleBrand,
        vehicleModel: vehicleModel,
        vehicleType: vehicleType,
        driverCardNumber: driverCardNumber,
        workingRegion: workingRegion,
        workingDistrict: workingDistrict,
        photo: photo,
        vehicleLicense: vehicleLicense,
        ibbCard: ibbCard,
        drivingLicense: drivingLicense,
        identityCard: identityCard,
      );
      
      // return full profile data as state
      return data;
    });
  }

  Future<void> logout() async {
    final service = ref.read(authServiceProvider);
    await service.logout();
    state = const AsyncValue.data(null);
  }
}
