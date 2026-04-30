import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
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
    void Function(JsonMap data)? onDriverWallet,
    void Function(JsonMap data)? onError,
    void Function(dynamic _)? onConnectError,
    void Function()? onConnected,
    void Function()? onDisconnected,
    List<String>? transports,
  }) {
    disconnect();
    final connectUrl = normalizeApiBaseUrl(_base);
    var resolvedTransports =
        List<String>.from(transports ?? (kIsWeb ? ['websocket', 'polling'] : ['polling']));
    if (kIsWeb) {
      // WebSocket-only transport has been flaky in this stack (web client parser crashes like
      // "Cannot read properties of undefined (reading 'payload')" on some hosts/proxies).
      // Polling is more stable with Flask-SocketIO threading mode across all roles.
      resolvedTransports = ['polling'];
    }
    final opts = socket_io.OptionBuilder()
        .setTransports(resolvedTransports)
        .disableAutoConnect()
        .setAuth({'token': token})
        .setQuery({'token': token})
        .build();
    // Engine.IO on mobile often probes WebSocket upgrade; some hosts/proxies return 200
    // without 101. Stay on long-polling only for native (avoids spurious WebSocketException).
    if (!kIsWeb) {
      opts['upgrade'] = false;
    }
    _socket = socket_io.io(connectUrl, opts);

    JsonMap? _normalizePayload(dynamic raw) {
      if (raw is Map) {
        return Map<String, dynamic>.from(raw);
      }
      if (raw is List && raw.isNotEmpty) {
        // socket_io_client may wrap event data in a single-item list.
        return _normalizePayload(raw.first);
      }
      if (raw is String) {
        final text = raw.trim();
        if (text.isEmpty) return null;
        try {
          return _normalizePayload(jsonDecode(text));
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    void mapEvent(dynamic raw, void Function(JsonMap) handler) {
      final payload = _normalizePayload(raw);
      if (payload != null) handler(payload);
    }

    _socket!.on('receive_message', (d) => mapEvent(d, onReceiveMessage ?? (_) {}));
    _socket!.on('ride_status', (d) => mapEvent(d, onRideStatus ?? (_) {}));
    _socket!.on('driver_wallet', (d) => mapEvent(d, onDriverWallet ?? (_) {}));
    _socket!.on('error', (d) => mapEvent(d, onError ?? (_) {}));
    _socket!.on('connect_error', onConnectError ?? (_) {});
    _socket!.on('connect', (_) => onConnected?.call());
    _socket!.on('disconnect', (_) => onDisconnected?.call());
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
