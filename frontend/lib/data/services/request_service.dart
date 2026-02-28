import '../../core/network/api_client.dart';
import '../../models/donation_request_dto.dart';

class RequestService {
  final ApiClient _apiClient;

  RequestService(this._apiClient);

  Future<void> createRequest({
    required String donorId,
    required String organType,
    required String urgency,
  }) async {
    await _apiClient.post(
      '/create-request',
      queryParameters: {
        'donor_id': donorId,
        'organ_type': organType,
        'urgency': urgency,
      },
    );
  }

  Future<List<DonationRequestDto>> fetchMyRequests(String userId) async {
    final response = await _apiClient.get('/my-requests/$userId');
    final data = _apiClient.decodeBody(response) as List<dynamic>;
    return data
        .whereType<Map<String, dynamic>>()
        .map(DonationRequestDto.fromJson)
        .toList();
  }
}
