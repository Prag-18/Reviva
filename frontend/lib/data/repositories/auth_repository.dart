import '../../core/utils/token_storage.dart';
import '../../models/user_dto.dart';
import '../services/auth_service.dart';

class AuthRepository {
  final AuthService _service;

  AuthRepository(this._service);

  Future<UserDto> login(String email, String password) async {
    final token = await _service.login(email, password);
    await TokenStorage.saveToken(token);
    return _service.getMe();
  }

  Future<UserDto?> restoreSession() async {
    final token = await TokenStorage.getToken();
    if (token == null || token.isEmpty) return null;
    try {
      return await _service.getMe();
    } catch (_) {
      await TokenStorage.clearToken();
      return null;
    }
  }

  Future<void> logout() async {
    await TokenStorage.clearToken();
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String role,
    required String donationType,
    String? bloodGroup,
    String? phone,
    double? latitude,
    double? longitude,
  }) {
    return _service.register(
      name: name,
      email: email,
      password: password,
      role: role,
      donationType: donationType,
      bloodGroup: bloodGroup,
      phone: phone,
      latitude: latitude,
      longitude: longitude,
    );
  }

  Future<void> updateLocation({
    required double latitude,
    required double longitude,
  }) {
    return _service.updateMyLocation(latitude: latitude, longitude: longitude);
  }

  Future<void> updateAvailability(bool available) {
    return _service.updateAvailability(available);
  }
}
