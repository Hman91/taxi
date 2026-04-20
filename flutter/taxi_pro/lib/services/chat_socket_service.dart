import 'dart:convert';

import 'package:socket_io_client/socket_io_client.dart' as socket_io;

import '../config.dart';

typedef JsonMap = Map<String, dynamic>;

/// Real-time chat + ride pushes; no UI logic (see `.cursor/rules.md`).
class ChatSocketService {
  ChatSocketService({String? baseUrl}) : _base = baseUrl ?? apiBaseUrl;

  final String _base;
  socket_io.Socket? _socket;

  bool get isConnected => _socket?.connected ?? false;

  void connect(
    String token, {
    void Function(JsonMap data)? onReceiveMessage,
    void Function(JsonMap data)? onRideStatus,
    void Function(JsonMap data)? onError,
    void Function(dynamic _)? onConnectError,
    List<String>? transports,
  }) {
    disconnect();
    _socket = socket_io.io(
      _base,
      socket_io.OptionBuilder()
          // Flask dev server on Windows is more stable with long-polling transport.
          // WebSocket upgrade can fail with Werkzeug and break live chat delivery.
          .setTransports(transports ?? ['polling'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    void mapEvent(dynamic raw, void Function(JsonMap) handler) {
      JsonMap? payload;
      if (raw is Map) {
        payload = Map<String, dynamic>.from(raw);
      } else if (raw is String) {
        final text = raw.trim();
        if (text.isNotEmpty) {
          try {
            final decoded = jsonDecode(text);
            if (decoded is Map) {
              payload = Map<String, dynamic>.from(decoded);
            }
          } catch (_) {
            // Ignore non-JSON payloads.
          }
        }
      }
      if (payload != null) {
        handler(payload);
      }
    }

    _socket!.on('receive_message', (d) => mapEvent(d, onReceiveMessage ?? (_) {}));
    _socket!.on('ride_status', (d) => mapEvent(d, onRideStatus ?? (_) {}));
    _socket!.on('error', (d) => mapEvent(d, onError ?? (_) {}));
    _socket!.on('connect_error', onConnectError ?? (_) {});
    _socket!.connect();
  }

  void joinConversation(int conversationId) {
    _socket?.emit('join_conversation', {'conversation_id': conversationId});
  }

  void leaveConversation(int conversationId) {
    _socket?.emit('leave_conversation', {'conversation_id': conversationId});
  }

  void sendMessage({required int conversationId, required String text}) {
    _socket?.emit('send_message', {
      'conversation_id': conversationId,
      'text': text,
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
