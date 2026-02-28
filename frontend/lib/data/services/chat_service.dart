import '../../core/network/api_client.dart';
import '../../models/chat_conversation_dto.dart';
import '../../models/chat_message_dto.dart';

class ChatService {
  final ApiClient _apiClient;

  ChatService(this._apiClient);

  Future<List<ChatConversationDto>> fetchConversations() async {
    final response = await _apiClient.get('/chat/conversations');
    final data = _apiClient.decodeBody(response) as List<dynamic>;
    return data
        .whereType<Map<String, dynamic>>()
        .map(ChatConversationDto.fromJson)
        .toList();
  }

  Future<List<ChatMessageDto>> fetchHistory(String otherUserId) async {
    final response = await _apiClient.get('/chat/history/$otherUserId');
    final data = _apiClient.decodeBody(response) as List<dynamic>;
    return data
        .whereType<Map<String, dynamic>>()
        .map(ChatMessageDto.fromJson)
        .toList();
  }
}
