import '../../models/donation_request_dto.dart';
import '../services/request_service.dart';

class RequestRepository {
  final RequestService _service;

  RequestRepository(this._service);

  Future<void> createRequest({
    required String donorId,
    required String organType,
    String urgency = 'medium',
  }) {
    return _service.createRequest(
      donorId: donorId,
      organType: organType,
      urgency: urgency,
    );
  }

  Future<List<DonationRequestDto>> fetchMyRequests(String userId) {
    return _service.fetchMyRequests(userId);
  }
}
