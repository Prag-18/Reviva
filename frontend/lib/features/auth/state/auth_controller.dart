import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/events/session_events.dart';
import '../../../models/user_dto.dart';

final authControllerProvider =
    AsyncNotifierProvider<AuthController, UserDto?>(AuthController.new);

class AuthController extends AsyncNotifier<UserDto?> {
  StreamSubscription<void>? _unauthorizedSubscription;

  @override
  Future<UserDto?> build() async {
    _unauthorizedSubscription = SessionEvents.unauthorizedStream.listen((_) {
      logout(silent: true);
    });
    ref.onDispose(() => _unauthorizedSubscription?.cancel());

    final user = await ref.read(authRepositoryProvider).restoreSession();
    if (user != null) {
      unawaited(ref.read(websocketManagerProvider).connect(user.id));
    }
    return user;
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).login(email, password),
    );
    final user = state.valueOrNull;
    if (user != null) {
      await ref.read(websocketManagerProvider).connect(user.id);
    }
  }

  Future<void> logout({bool silent = false}) async {
    await ref.read(authRepositoryProvider).logout();
    await ref.read(websocketManagerProvider).disconnect();
    state = const AsyncData(null);
  }

  Future<void> refreshMe() async {
    final current = state.valueOrNull;
    if (current == null) return;
    state = await AsyncValue.guard(
      () => ref.read(authServiceProvider).getMe(),
    );
  }
}
