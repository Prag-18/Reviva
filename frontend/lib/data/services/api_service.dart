import '../../core/network/api_client.dart';

@Deprecated('Use dedicated services/repositories instead.')
class ApiService {
  final ApiClient _api = ApiClient.instance;

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _api.post(
      '/login',
      authorized: false,
      formUrlEncoded: true,
      body: {'username': email, 'password': password},
    );
    return (_api.decodeBody(response) as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> getMe() async {
    final response = await _api.get('/me');
    return (_api.decodeBody(response) as Map).cast<String, dynamic>();
  }

  Future<List<dynamic>> getChatConversations() async {
    final response = await _api.get('/chat/conversations');
    return _api.decodeBody(response) as List<dynamic>;
  }

  Future<List<dynamic>> getChatHistory(String otherUserId) async {
    final response = await _api.get('/chat/history/$otherUserId');
    return _api.decodeBody(response) as List<dynamic>;
  }

  Future<List<dynamic>> getNearbyDonors({
    required double latitude,
    required double longitude,
    required String organType,
    double radiusKm = 5,
  }) async {
    final response = await _api.get(
      '/nearby-donors',
      queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
        'organ_type': organType,
        'radius_km': radiusKm,
      },
    );
    return _api.decodeBody(response) as List<dynamic>;
  }

  Future<void> createRequest({
    required String donorId,
    required String organType,
    String urgency = 'medium',
  }) async {
    await _api.post(
      '/create-request',
      queryParameters: {
        'donor_id': donorId,
        'organ_type': organType,
        'urgency': urgency,
      },
    );
  }
}
