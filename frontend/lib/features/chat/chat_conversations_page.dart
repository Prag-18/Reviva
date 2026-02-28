import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/user_dto.dart';
import 'chat_screen.dart';
import 'state/chat_conversations_controller.dart';

class ChatConversationsPage extends ConsumerStatefulWidget {
  final UserDto user;

  const ChatConversationsPage({super.key, required this.user});

  @override
  ConsumerState<ChatConversationsPage> createState() =>
      _ChatConversationsPageState();
}

class _ChatConversationsPageState extends ConsumerState<ChatConversationsPage> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(chatConversationsControllerProvider.notifier).refresh(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatConversationsControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(chatConversationsControllerProvider.notifier).refresh(),
          child: Builder(
            builder: (_) {
              if (state.loading && state.conversations.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.error != null && state.conversations.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Text(state.error!, textAlign: TextAlign.center),
                          const SizedBox(height: 10),
                          OutlinedButton(
                            onPressed: () => ref
                                .read(chatConversationsControllerProvider.notifier)
                                .refresh(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }

              if (state.conversations.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 180),
                    Center(child: Text('No conversations yet')),
                  ],
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: state.conversations.length,
                itemBuilder: (context, index) {
                  final convo = state.conversations[index];
                  final subtitle = convo.lastMessage.isEmpty
                      ? 'No messages yet'
                      : convo.lastMessage;
                  final timeLabel = convo.lastMessageAt == null
                      ? ''
                      : DateFormat('hh:mm a').format(convo.lastMessageAt!.toLocal());

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(convo.otherUserName),
                      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (timeLabel.isNotEmpty)
                            Text(timeLabel, style: Theme.of(context).textTheme.bodySmall),
                          const SizedBox(height: 6),
                          if (convo.unread)
                            const Icon(Icons.circle, size: 10, color: Colors.red),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              user: widget.user,
                              otherUserId: convo.otherUserId,
                              otherUserName: convo.otherUserName,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
