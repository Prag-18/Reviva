import '../../models/chat_conversation_dto.dart';
import '../../models/chat_message_dto.dart';
import '../services/chat_service.dart';

class ChatRepository {
  final ChatService _service;

  ChatRepository(this._service);

  Future<List<ChatConversationDto>> fetchConversations() {
    return _service.fetchConversations();
  }

  Future<List<ChatMessageDto>> fetchHistory(String otherUserId) {
    return _service.fetchHistory(otherUserId);
  }
}
