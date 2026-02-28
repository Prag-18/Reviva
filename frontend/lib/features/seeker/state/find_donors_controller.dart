import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/location_service.dart';
import '../../../models/donor_dto.dart';

class FindDonorsState {
  final List<DonorDto> donors;
  final bool loading;
  final String? error;
  final String organType;
  final double radiusKm;

  const FindDonorsState({
    required this.donors,
    required this.loading,
    required this.error,
    required this.organType,
    required this.radiusKm,
  });

  factory FindDonorsState.initial() => const FindDonorsState(
        donors: [],
        loading: false,
        error: null,
        organType: 'blood',
        radiusKm: 5,
      );

  FindDonorsState copyWith({
    List<DonorDto>? donors,
    bool? loading,
    String? error,
    String? organType,
    double? radiusKm,
  }) {
    return FindDonorsState(
      donors: donors ?? this.donors,
      loading: loading ?? this.loading,
      error: error,
      organType: organType ?? this.organType,
      radiusKm: radiusKm ?? this.radiusKm,
    );
  }
}

final findDonorsControllerProvider =
    StateNotifierProvider<FindDonorsController, FindDonorsState>(
  (ref) => FindDonorsController(ref),
);

class FindDonorsController extends StateNotifier<FindDonorsState> {
  final Ref _ref;

  FindDonorsController(this._ref) : super(FindDonorsState.initial());

  void setOrganType(String organType) {
    state = state.copyWith(organType: organType, error: null);
  }

  void setRadius(double radiusKm) {
    state = state.copyWith(radiusKm: radiusKm, error: null);
  }

  Future<void> findDonors() async {
    state = state.copyWith(loading: true, error: null);

    try {
      final position = await LocationService.getCurrentLocation();
      final donors = await _ref.read(donorRepositoryProvider).fetchNearbyDonors(
            latitude: position.latitude,
            longitude: position.longitude,
            organType: state.organType,
            radiusKm: state.radiusKm,
          );
      state = state.copyWith(donors: donors, loading: false, error: null);
    } on ApiException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(
        loading: false,
        error: 'Unable to fetch donors. Please try again.',
      );
    }
  }

  Future<void> sendRequest(String donorId) {
    return _ref.read(requestRepositoryProvider).createRequest(
          donorId: donorId,
          organType: state.organType,
        );
  }
}
