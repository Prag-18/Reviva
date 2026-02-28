enum MessageSendState { sending, sent, delivered, read, failed }

class ChatMessageDto {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime createdAt;
  final bool isRead;
  final MessageSendState sendState;
  final bool isOptimistic;

  const ChatMessageDto({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.createdAt,
    required this.isRead,
    required this.sendState,
    this.isOptimistic = false,
  });

  factory ChatMessageDto.fromJson(Map<String, dynamic> json) {
    final status = json['status']?.toString();
    final isRead = json['is_read'] == true || status == 'read';

    MessageSendState sendState;
    switch (status) {
      case 'read':
        sendState = MessageSendState.read;
        break;
      case 'delivered':
        sendState = MessageSendState.delivered;
        break;
      case 'sent':
        sendState = MessageSendState.sent;
        break;
      default:
        sendState = isRead ? MessageSendState.read : MessageSendState.delivered;
    }

    return ChatMessageDto(
      id: json['id']?.toString() ?? '',
      senderId: json['sender_id'].toString(),
      receiverId: json['receiver_id'].toString(),
      content: json['content']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      isRead: isRead,
      sendState: sendState,
    );
  }

  ChatMessageDto copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? content,
    DateTime? createdAt,
    bool? isRead,
    MessageSendState? sendState,
    bool? isOptimistic,
  }) {
    return ChatMessageDto(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      sendState: sendState ?? this.sendState,
      isOptimistic: isOptimistic ?? this.isOptimistic,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
    };
  }
}
