import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../models/chat_conversation_dto.dart';

class ChatConversationsState {
  final List<ChatConversationDto> conversations;
  final bool loading;
  final String? error;

  const ChatConversationsState({
    required this.conversations,
    required this.loading,
    required this.error,
  });

  factory ChatConversationsState.initial() => const ChatConversationsState(
        conversations: [],
        loading: false,
        error: null,
      );

  ChatConversationsState copyWith({
    List<ChatConversationDto>? conversations,
    bool? loading,
    String? error,
  }) {
    return ChatConversationsState(
      conversations: conversations ?? this.conversations,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

final chatConversationsControllerProvider =
    StateNotifierProvider<ChatConversationsController, ChatConversationsState>(
  (ref) => ChatConversationsController(ref),
);

class ChatConversationsController extends StateNotifier<ChatConversationsState> {
  final Ref _ref;
  StreamSubscription<Map<String, dynamic>>? _subscription;

  ChatConversationsController(this._ref)
      : super(ChatConversationsState.initial()) {
    _subscription = _ref.read(websocketManagerProvider).stream.listen((event) {
      final type = event['type']?.toString();
      if (type == 'chat_message' ||
          type == 'messages_read' ||
          type == 'read_receipt' ||
          type == 'status') {
        refresh();
      }
    });
    _ref.onDispose(() => _subscription?.cancel());
  }

  Future<void> refresh() async {
    if (state.conversations.isEmpty) {
      state = state.copyWith(loading: true, error: null);
    }

    try {
      final items = await _ref.read(chatRepositoryProvider).fetchConversations();
      state = state.copyWith(
        conversations: items,
        loading: false,
        error: null,
      );
    } catch (_) {
      state = state.copyWith(
        loading: false,
        error: 'Unable to load conversations',
      );
    }
  }
}
