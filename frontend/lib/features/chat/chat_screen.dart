import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/chat_message_dto.dart';
import '../../models/user_dto.dart';
import 'state/chat_thread_controller.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final UserDto user;
  final String otherUserId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.user,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _typingDebounce;

  @override
  void initState() {
    super.initState();
    ref.listenManual(chatThreadControllerProvider(widget.otherUserId), (prev, next) {
      final prevCount = prev?.messages.length ?? 0;
      if (next.messages.length > prevCount) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    });
  }

  @override
  void dispose() {
    _typingDebounce?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 100,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
    );
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    await ref.read(chatThreadControllerProvider(widget.otherUserId).notifier).sendStopTyping();
    await ref.read(chatThreadControllerProvider(widget.otherUserId).notifier).sendMessage(text);
  }

  void _onTextChanged(String value) {
    final notifier = ref.read(chatThreadControllerProvider(widget.otherUserId).notifier);
    if (value.trim().isNotEmpty) {
      notifier.sendTyping();
    }
    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(milliseconds: 900), () {
      notifier.sendStopTyping();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatThreadControllerProvider(widget.otherUserId));

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputBackground = isDark ? const Color(0xFF1F2937) : Colors.white;
    final inputTextColor = isDark ? Colors.white : Colors.black;
    final inputHintColor = isDark ? Colors.white70 : const Color(0xFF888888);

    final presenceLabel =
        state.presence == 'online' ? 'Online' : 'Last seen recently';
    final presenceColor =
        state.presence == 'online' ? const Color(0xFF16A34A) : Colors.grey;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherUserName),
            const SizedBox(height: 2),
            Text(
              presenceLabel,
              style: TextStyle(fontSize: 12, color: presenceColor),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Builder(
              builder: (_) {
                if (state.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.error != null && state.messages.isEmpty) {
                  return Center(child: Text(state.error!));
                }

                if (state.messages.isEmpty) {
                  return const Center(child: Text('Start the conversation'));
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: state.messages.length,
                  itemBuilder: (context, index) {
                    final msg = state.messages[index];
                    final prev = index > 0 ? state.messages[index - 1] : null;
                    final showDate = prev == null ||
                        !_isSameDay(prev.createdAt, msg.createdAt);

                    return Column(
                      children: [
                        if (showDate)
                          _DateHeader(date: msg.createdAt),
                        _MessageBubble(
                          message: msg,
                          isMe: msg.senderId == widget.user.id,
                          onRetry: () => ref
                              .read(chatThreadControllerProvider(widget.otherUserId).notifier)
                              .retryMessage(msg.id),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          if (state.otherUserTyping)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Typing...'),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: TextStyle(color: inputTextColor),
                    onChanged: _onTextChanged,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: inputHintColor),
                      filled: true,
                      fillColor: inputBackground,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _send,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _DateHeader extends StatelessWidget {
  final DateTime date;

  const _DateHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    final label = DateFormat('dd MMM yyyy').format(date.toLocal());
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessageDto message;
  final bool isMe;
  final VoidCallback onRetry;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final timeText = DateFormat('hh:mm a').format(message.createdAt.toLocal());

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.92, end: 1),
        duration: const Duration(milliseconds: 180),
        builder: (context, value, child) {
          return Transform.scale(scale: value, child: child);
        },
        child: Container(
          constraints: const BoxConstraints(maxWidth: 300),
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isMe
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.9)
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                message.content,
                style: TextStyle(
                  color: isMe ? Colors.white : Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeText,
                    style: TextStyle(
                      fontSize: 11,
                      color: isMe
                          ? Colors.white.withValues(alpha: 0.9)
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 6),
                    _StatusIcon(message: message, onRetry: onRetry),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final ChatMessageDto message;
  final VoidCallback onRetry;

  const _StatusIcon({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    switch (message.sendState) {
      case MessageSendState.sending:
        return const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(strokeWidth: 1.6, color: Colors.white),
        );
      case MessageSendState.sent:
        return const Icon(Icons.check, size: 14, color: Colors.white);
      case MessageSendState.delivered:
        return const Icon(Icons.done_all, size: 14, color: Colors.white70);
      case MessageSendState.read:
        return const Icon(Icons.done_all, size: 14, color: Colors.lightBlueAccent);
      case MessageSendState.failed:
        return GestureDetector(
          onTap: onRetry,
          child: const Icon(Icons.error_outline, size: 14, color: Colors.yellowAccent),
        );
    }
  }
}
