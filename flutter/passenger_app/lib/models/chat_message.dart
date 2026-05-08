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
    final disp = json['display_text'];
    final orig = json['original_text'];
    final original =
        orig == null ? '' : (orig is String ? orig : orig.toString());
    final rawDisplay = disp == null
        ? null
        : (disp is String ? disp : disp.toString());
    final idRaw = json['message_id'] ?? json['id'];
    final mid = idRaw is num
        ? idRaw.toInt()
        : int.tryParse(idRaw?.toString() ?? '') ?? 0;
    final sidRaw = json['sender_user_id'] ?? json['sender_id'];
    final sid = sidRaw is num
        ? sidRaw.toInt()
        : int.tryParse(sidRaw?.toString() ?? '') ?? 0;
    final tr = json['translated_text'];
    final sn = json['sender_name'];
    final ca = json['created_at'];
    return ChatMessage(
      id: mid,
      originalText: original,
      translatedText: tr is String ? tr : (tr == null ? null : tr.toString()),
      displayText: (rawDisplay != null && rawDisplay.isNotEmpty)
          ? rawDisplay
          : original,
      senderUserId: sid,
      senderName: sn is String ? sn : (sn == null ? null : sn.toString()),
      createdAt: ca is String ? ca : (ca == null ? null : ca.toString()),
    );
  }
}
