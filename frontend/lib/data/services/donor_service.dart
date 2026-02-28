import '../../core/network/api_client.dart';
import '../../models/donor_dto.dart';

class DonorService {
  final ApiClient _apiClient;

  DonorService(this._apiClient);

  Future<List<DonorDto>> fetchNearbyDonors({
    required double latitude,
    required double longitude,
    required String organType,
    required double radiusKm,
  }) async {
    final response = await _apiClient.get(
      '/nearby-donors',
      queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
        'organ_type': organType,
        'radius_km': radiusKm,
      },
    );
    final data = _apiClient.decodeBody(response) as List<dynamic>;
    return data
        .whereType<Map<String, dynamic>>()
        .map(DonorDto.fromJson)
        .toList();
  }
}
