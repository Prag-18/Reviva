import '../../models/donor_dto.dart';
import '../services/donor_service.dart';

class DonorRepository {
  final DonorService _service;

  DonorRepository(this._service);

  Future<List<DonorDto>> fetchNearbyDonors({
    required double latitude,
    required double longitude,
    required String organType,
    required double radiusKm,
  }) {
    return _service.fetchNearbyDonors(
      latitude: latitude,
      longitude: longitude,
      organType: organType,
      radiusKm: radiusKm,
    );
  }
}
