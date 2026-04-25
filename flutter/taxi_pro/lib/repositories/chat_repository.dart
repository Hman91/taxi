import '../api/client.dart';
import '../models/chat_message.dart';
import '../services/chat_socket_service.dart';

/// REST history + Socket.IO stream wiring (see `.cursor/plan.md` Step 8).
class ChatRepository {
  ChatRepository({TaxiApiClient? api, ChatSocketService? socket})
      : _api = api ?? TaxiApiClient(),
        _socket = socket ?? ChatSocketService();

  final TaxiApiClient _api;
  final ChatSocketService _socket;

  ChatSocketService get socket => _socket;

  Future<List<ChatMessage>> loadMessages({
    required String token,
    required int conversationId,
    int? beforeId,
    int limit = 50,
  }) =>
      _api.listConversationMessages(
        token: token,
        conversationId: conversationId,
        beforeId: beforeId,
        limit: limit,
      );
}
