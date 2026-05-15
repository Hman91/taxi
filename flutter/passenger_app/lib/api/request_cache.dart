import 'dart:async';

/// In-flight deduplication + short TTL cache for idempotent reads.
class RequestCache {
  RequestCache._();
  static final RequestCache instance = RequestCache._();

  final Map<String, _Entry> _entries = {};
  final Map<String, Future<dynamic>> _inFlight = {};

  Future<T> getOrFetch<T>(
    String key,
    Future<T> Function() fetch, {
    Duration ttl = const Duration(seconds: 45),
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final hit = _entries[key];
      if (hit != null && !hit.isExpired && hit.value is T) {
        return hit.value as T;
      }
      final pending = _inFlight[key];
      if (pending != null) return await pending as T;
    } else {
      _entries.remove(key);
      _inFlight.remove(key);
    }

    final future = fetch();
    _inFlight[key] = future;
    try {
      final value = await future;
      _entries[key] = _Entry(value, DateTime.now().add(ttl));
      return value;
    } finally {
      _inFlight.remove(key);
    }
  }

  void invalidate([String? prefix]) {
    if (prefix == null) {
      _entries.clear();
      return;
    }
    _entries.removeWhere((k, _) => k.startsWith(prefix));
  }
}

class _Entry {
  _Entry(this.value, this.expiresAt);
  final dynamic value;
  final DateTime expiresAt;
  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
