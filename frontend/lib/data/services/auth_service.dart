import '../../core/network/api_client.dart';
import '../../models/user_dto.dart';

class AuthService {
  final ApiClient _apiClient;

  AuthService(this._apiClient);

  Future<String> login(String email, String password) async {
    final response = await _apiClient.post(
      '/login',
      authorized: false,
      formUrlEncoded: true,
      body: {'username': email, 'password': password},
    );

    final data = _apiClient.decodeBody(response) as Map<String, dynamic>;
    return data['access_token']?.toString() ?? '';
  }

  Future<UserDto> getMe() async {
    final response = await _apiClient.get('/me');
    final data = _apiClient.decodeBody(response) as Map<String, dynamic>;
    return UserDto.fromJson(data);
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
  }) async {
    final queryParameters = <String, dynamic>{
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      'donation_type': donationType,
      if (bloodGroup?.isNotEmpty ?? false) 'blood_group': bloodGroup,
      if (phone?.isNotEmpty ?? false) 'phone': phone,
    };
    if (latitude != null) {
      queryParameters['latitude'] = latitude;
    }
    if (longitude != null) {
      queryParameters['longitude'] = longitude;
    }

    await _apiClient.post(
      '/register',
      authorized: false,
      queryParameters: queryParameters,
    );
  }

  Future<void> updateMyLocation({
    required double latitude,
    required double longitude,
  }) async {
    await _apiClient.put(
      '/users/me',
      body: {'latitude': latitude, 'longitude': longitude},
    );
  }

  Future<void> updateAvailability(bool available) async {
    await _apiClient.put('/users/me', body: {'available': available});
  }
}
