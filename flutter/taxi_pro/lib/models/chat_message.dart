/// Chat line from REST or Socket (`display_text` is server-localized for the viewer).
class ChatMessage {
  ChatMessage({
    required this.id,
    required this.originalText,
    this.translatedText,
    required this.displayText,
    required this.senderUserId,
    this.senderName,
    this.createdAt,
  });

  final int id;
  final String originalText;
  final String? translatedText;
  final String displayText;
  final int senderUserId;
  final String? senderName;
  final String? createdAt;

  /// Prefer `display_text` from API / socket (translation on delivery).
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final rawDisplay = json['display_text'] as String?;
    final original = json['original_text'] as String? ?? '';
    final idRaw = json['message_id'] ?? json['id'];
    return ChatMessage(
      id: idRaw is num ? idRaw.toInt() : int.parse(idRaw.toString()),
      originalText: original,
      translatedText: json['translated_text'] as String?,
      displayText: rawDisplay ?? original,
      senderUserId: ((json['sender_user_id'] ?? json['sender_id']) as num?)?.toInt() ?? 0,
      senderName: json['sender_name'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }
}
