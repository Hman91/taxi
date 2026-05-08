import '../models/chat_message.dart';
import '../services/taxi_app_service.dart';

/// Matches backend chat rules: conversations can exist once a ride progressed past `pending`.
bool rideMayHaveConversation(String status) =>
    status == 'accepted' ||
    status == 'ongoing' ||
    status == 'completed' ||
    status == 'cancelled';

/// True when [createdAtIso] is recent enough that a poll with no prior watermark should
/// still surface a heads-up notification (avoids alerting on stale single-message threads).
bool chatTimestampLooksFresh({
  String? createdAtIso,
  Duration freshWithin = const Duration(minutes: 4),
}) {
  if (createdAtIso == null || createdAtIso.trim().isEmpty) return false;
  final t = DateTime.tryParse(createdAtIso.trim());
  if (t == null) return false;
  final created = t.toUtc();
  final now = DateTime.now().toUtc();
  if (created.isAfter(now.add(const Duration(seconds: 30)))) {
    return true;
  }
  return now.difference(created) <= freshWithin;
}

/// Shared logic for HTTP fallback when counting new chat messages for notifications.
class ChatUnreadPollResult {
  ChatUnreadPollResult({
    required this.incomingCount,
    required this.latestIncoming,
    required this.newWatermark,
  });

  final int incomingCount;
  final ChatMessage? latestIncoming;
  final int newWatermark;
}

ChatUnreadPollResult computeUnreadChatDelta({
  required List<ChatMessage> msgs,
  required int myUserId,
  required int storedWatermark,
}) {
  if (msgs.isEmpty) {
    return ChatUnreadPollResult(
      incomingCount: 0,
      latestIncoming: null,
      newWatermark: storedWatermark,
    );
  }
  var maxId = 0;
  for (final m in msgs) {
    if (m.id > maxId) maxId = m.id;
  }

  if (storedWatermark == 0) {
    ChatMessage? latestFreshOther;
    var freshOtherCount = 0;
    for (final m in msgs) {
      if (m.senderUserId != myUserId &&
          chatTimestampLooksFresh(createdAtIso: m.createdAt)) {
        freshOtherCount++;
        if (latestFreshOther == null || m.id > latestFreshOther.id) {
          latestFreshOther = m;
        }
      }
    }
    return ChatUnreadPollResult(
      incomingCount: freshOtherCount,
      latestIncoming: latestFreshOther,
      newWatermark: maxId,
    );
  }

  ChatMessage? latestIncoming;
  var incomingCount = 0;
  for (final m in msgs) {
    if (m.id > storedWatermark && m.senderUserId != myUserId) {
      incomingCount++;
      if (latestIncoming == null || m.id > latestIncoming.id) {
        latestIncoming = m;
      }
    }
  }
  return ChatUnreadPollResult(
    incomingCount: incomingCount,
    latestIncoming: latestIncoming,
    newWatermark: maxId,
  );
}

/// Max message id in the list, or 0 when empty (for read watermarks).
int maxChatMessageId(Iterable<ChatMessage> msgs) {
  var m = 0;
  for (final x in msgs) {
    if (x.id > m) m = x.id;
  }
  return m;
}

/// Resolves `/rides/:id/conversation` once and keeps ride↔conversation maps in sync for polling.
Future<int?> cachedOrFetchConversationId({
  required TaxiAppService api,
  required String token,
  required int rideId,
  required Map<int, int> conversationIdByRideId,
  Map<int, int>? rideIdByConversationId,
}) async {
  final hit = conversationIdByRideId[rideId];
  if (hit != null) return hit;
  try {
    final info = await api.getRideConversation(token: token, rideId: rideId);
    if (info == null) return null;
    final cid = info.conversationId;
    conversationIdByRideId[rideId] = cid;
    rideIdByConversationId?[cid] = rideId;
    return cid;
  } catch (_) {
    return null;
  }
}
