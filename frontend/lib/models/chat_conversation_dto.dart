class ChatConversationDto {
  final String otherUserId;
  final String otherUserName;
  final String? otherUserRole;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final bool unread;

  const ChatConversationDto({
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserRole,
    required this.lastMessage,
    this.lastMessageAt,
    required this.unread,
  });

  factory ChatConversationDto.fromJson(Map<String, dynamic> json) {
    return ChatConversationDto(
      otherUserId: json['other_user_id'].toString(),
      otherUserName: json['other_user_name']?.toString() ?? 'Unknown user',
      otherUserRole: json['other_user_role']?.toString(),
      lastMessage: json['last_message']?.toString() ?? '',
      lastMessageAt: json['last_message_at'] == null
          ? null
          : DateTime.tryParse(json['last_message_at'].toString()),
      unread: json['unread'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'other_user_id': otherUserId,
      'other_user_name': otherUserName,
      'other_user_role': otherUserRole,
      'last_message': lastMessage,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'unread': unread,
    };
  }
}
