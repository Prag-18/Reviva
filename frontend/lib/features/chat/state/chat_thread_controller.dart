import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../features/auth/state/auth_controller.dart';
import '../../../models/chat_message_dto.dart';

class ChatThreadState {
  final List<ChatMessageDto> messages;
  final bool loading;
  final bool otherUserTyping;
  final String presence;
  final String? error;

  const ChatThreadState({
    required this.messages,
    required this.loading,
    required this.otherUserTyping,
    required this.presence,
    required this.error,
  });

  factory ChatThreadState.initial() => const ChatThreadState(
        messages: [],
        loading: false,
        otherUserTyping: false,
        presence: 'offline',
        error: null,
      );

  ChatThreadState copyWith({
    List<ChatMessageDto>? messages,
    bool? loading,
    bool? otherUserTyping,
    String? presence,
    String? error,
  }) {
    return ChatThreadState(
      messages: messages ?? this.messages,
      loading: loading ?? this.loading,
      otherUserTyping: otherUserTyping ?? this.otherUserTyping,
      presence: presence ?? this.presence,
      error: error,
    );
  }
}

final chatThreadControllerProvider = StateNotifierProvider.family<
    ChatThreadController,
    ChatThreadState,
    String>((ref, otherUserId) => ChatThreadController(ref, otherUserId));

class ChatThreadController extends StateNotifier<ChatThreadState> {
  final Ref _ref;
  final String otherUserId;
  StreamSubscription<Map<String, dynamic>>? _subscription;

  ChatThreadController(this._ref, this.otherUserId)
      : super(ChatThreadState.initial()) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(loading: true, error: null);

    final user = _ref.read(authControllerProvider).valueOrNull;
    if (user == null) {
      state = state.copyWith(loading: false, error: 'Not authenticated');
      return;
    }

    await _ref.read(websocketManagerProvider).connect(user.id);

    _subscription = _ref.read(websocketManagerProvider).stream.listen(_onEvent);
    _ref.onDispose(() => _subscription?.cancel());

    await loadHistory();
  }

  Future<void> loadHistory() async {
    try {
      final history = await _ref.read(chatRepositoryProvider).fetchHistory(otherUserId);
      state = state.copyWith(messages: history, loading: false, error: null);
    } catch (_) {
      state = state.copyWith(loading: false, error: 'Unable to load chat history');
    }
  }

  void _onEvent(Map<String, dynamic> event) {
    final currentUser = _ref.read(authControllerProvider).valueOrNull;
    if (currentUser == null) return;

    final type = event['type']?.toString();

    if (type == 'typing' &&
        (event['sender_id']?.toString() == otherUserId ||
            event['from']?.toString() == otherUserId)) {
      state = state.copyWith(otherUserTyping: true);
      return;
    }

    if (type == 'stop_typing' &&
        (event['sender_id']?.toString() == otherUserId ||
            event['from']?.toString() == otherUserId)) {
      state = state.copyWith(otherUserTyping: false);
      return;
    }

    if (type == 'status' && event['user_id']?.toString() == otherUserId) {
      state = state.copyWith(presence: event['status']?.toString() ?? 'offline');
      return;
    }

    if (type == 'read_receipt') {
      final msgId = event['message_id']?.toString();
      if (msgId == null) return;
      _markReadById(msgId);
      return;
    }

    if (type != 'chat_message') return;

    final senderId = event['sender_id']?.toString();
    final receiverId = event['receiver_id']?.toString();
    final isRelevant =
        (senderId == otherUserId && receiverId == currentUser.id) ||
            (senderId == currentUser.id && receiverId == otherUserId);

    if (!isRelevant) return;

    final incoming = ChatMessageDto.fromJson(event);
    final optimisticIndex = state.messages.indexWhere((message) =>
        message.isOptimistic &&
        message.senderId == currentUser.id &&
        message.receiverId == otherUserId &&
        message.content == incoming.content);

    if (optimisticIndex != -1) {
      final updated = List<ChatMessageDto>.from(state.messages);
      updated[optimisticIndex] = incoming;
      state = state.copyWith(messages: updated, otherUserTyping: false);
      return;
    }

    state = state.copyWith(
      messages: [...state.messages, incoming],
      otherUserTyping: false,
    );
  }

  Future<void> sendTyping() async {
    await _ref.read(websocketManagerProvider).send({
      'type': 'typing',
      'receiver_id': otherUserId,
    });
  }

  Future<void> sendStopTyping() async {
    await _ref.read(websocketManagerProvider).send({
      'type': 'stop_typing',
      'receiver_id': otherUserId,
    });
  }

  Future<void> sendMessage(String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;

    final currentUser = _ref.read(authControllerProvider).valueOrNull;
    if (currentUser == null) return;

    final optimistic = ChatMessageDto(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(9999)}',
      senderId: currentUser.id,
      receiverId: otherUserId,
      content: trimmed,
      createdAt: DateTime.now(),
      isRead: false,
      sendState: MessageSendState.sending,
      isOptimistic: true,
    );

    state = state.copyWith(messages: [...state.messages, optimistic]);

    try {
      await _ref.read(websocketManagerProvider).send({
        'type': 'message',
        'receiver_id': otherUserId,
        'content': trimmed,
      });

      _updateMessage(
        optimistic.id,
        (m) => m.copyWith(sendState: MessageSendState.sent),
      );
    } catch (_) {
      _updateMessage(
        optimistic.id,
        (m) => m.copyWith(sendState: MessageSendState.failed),
      );
    }
  }

  Future<void> retryMessage(String localId) async {
    final message = state.messages.firstWhere(
      (m) => m.id == localId,
      orElse: () => ChatMessageDto(
        id: '',
        senderId: '',
        receiverId: '',
        content: '',
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
        isRead: false,
        sendState: MessageSendState.failed,
      ),
    );

    if (message.id.isEmpty) return;

    _updateMessage(localId, (m) => m.copyWith(sendState: MessageSendState.sending));

    try {
      await _ref.read(websocketManagerProvider).send({
        'type': 'message',
        'receiver_id': otherUserId,
        'content': message.content,
      });
      _updateMessage(localId, (m) => m.copyWith(sendState: MessageSendState.sent));
    } catch (_) {
      _updateMessage(localId, (m) => m.copyWith(sendState: MessageSendState.failed));
    }
  }

  void _markReadById(String messageId) {
    _updateMessage(messageId, (m) => m.copyWith(
          isRead: true,
          sendState: MessageSendState.read,
        ));
  }

  void _updateMessage(String id, ChatMessageDto Function(ChatMessageDto) updater) {
    final idx = state.messages.indexWhere((m) => m.id == id);
    if (idx == -1) return;
    final updated = List<ChatMessageDto>.from(state.messages);
    updated[idx] = updater(updated[idx]);
    state = state.copyWith(messages: updated);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
