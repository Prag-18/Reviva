import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../features/auth/state/auth_controller.dart';
import '../../../models/donation_request_dto.dart';

class RequestsState {
  final List<DonationRequestDto> requests;
  final bool loading;
  final String? error;

  const RequestsState({
    required this.requests,
    required this.loading,
    required this.error,
  });

  factory RequestsState.initial() => const RequestsState(
        requests: [],
        loading: false,
        error: null,
      );

  RequestsState copyWith({
    List<DonationRequestDto>? requests,
    bool? loading,
    String? error,
  }) {
    return RequestsState(
      requests: requests ?? this.requests,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

final requestsControllerProvider =
    StateNotifierProvider<RequestsController, RequestsState>(
  (ref) => RequestsController(ref),
);

class RequestsController extends StateNotifier<RequestsState> {
  final Ref _ref;
  StreamSubscription<Map<String, dynamic>>? _wsSubscription;

  RequestsController(this._ref) : super(RequestsState.initial()) {
    _initRealtime();
  }

  void _initRealtime() {
    _wsSubscription = _ref.read(websocketManagerProvider).stream.listen((event) {
      final type = event['type']?.toString();
      if (type == 'request_updated' ||
          type == 'request_accepted' ||
          type == 'request_rejected') {
        refresh();
      }
    });
    _ref.onDispose(() => _wsSubscription?.cancel());
  }

  Future<void> refresh() async {
    final user = _ref.read(authControllerProvider).valueOrNull;
    if (user == null) return;

    if (state.requests.isEmpty) {
      state = state.copyWith(loading: true, error: null);
    } else {
      state = state.copyWith(error: null);
    }

    try {
      final items = await _ref.read(requestRepositoryProvider).fetchMyRequests(user.id);
      state = state.copyWith(requests: items, loading: false, error: null);
    } catch (_) {
      state = state.copyWith(
        loading: false,
        error: 'Unable to load requests',
      );
    }
  }
}
