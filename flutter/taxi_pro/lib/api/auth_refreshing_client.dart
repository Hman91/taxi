import 'dart:async';

import 'package:http/http.dart' as http;

import 'auth_token_store.dart';

/// HTTP client: always sends the latest token from [AuthTokenStore], refreshes on 401, retries once.
class AuthRefreshingClient extends http.BaseClient {
  AuthRefreshingClient({http.Client? inner}) : _inner = inner ?? http.Client();

  final http.Client _inner;
  Completer<bool>? _refreshCompleter;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    _applyBearer(request);
    var response = await _inner.send(request);
    if (!_shouldAttemptRefresh(response, request)) {
      return response;
    }

    final refreshed = await _refreshOnce();
    if (!refreshed) return response;

    final retry = _copyRequest(request);
    _applyBearer(retry);
    return _inner.send(retry);
  }

  Future<bool> _refreshOnce() async {
    final inFlight = _refreshCompleter;
    if (inFlight != null) return inFlight.future;

    final c = Completer<bool>();
    _refreshCompleter = c;
    try {
      final ok = await AuthTokenStore.instance.refreshSession();
      c.complete(ok);
      return ok;
    } catch (_) {
      c.complete(false);
      return false;
    } finally {
      if (identical(_refreshCompleter, c)) {
        _refreshCompleter = null;
      }
    }
  }

  void _applyBearer(http.BaseRequest request) {
    final token = AuthTokenStore.instance.bearerForApi();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    } else {
      request.headers.remove('Authorization');
    }
  }

  bool _shouldAttemptRefresh(
    http.StreamedResponse response,
    http.BaseRequest request,
  ) {
    if (response.statusCode != 401) return false;
    final path = request.url.path;
    if (path.contains('/auth/refresh') ||
        path.contains('/auth/login') ||
        path.contains('/auth/logout')) {
      return false;
    }
    final rt = AuthTokenStore.instance.refreshToken;
    return rt != null && rt.isNotEmpty;
  }

  http.BaseRequest _copyRequest(http.BaseRequest request) {
    if (request is http.Request) {
      return http.Request(request.method, request.url)
        ..bodyBytes = request.bodyBytes
        ..headers.addAll(request.headers)
        ..followRedirects = request.followRedirects
        ..maxRedirects = request.maxRedirects
        ..persistentConnection = request.persistentConnection;
    }
    if (request is http.MultipartRequest) {
      final copy = http.MultipartRequest(request.method, request.url)
        ..fields.addAll(request.fields)
        ..headers.addAll(request.headers)
        ..followRedirects = request.followRedirects
        ..maxRedirects = request.maxRedirects
        ..persistentConnection = request.persistentConnection;
      copy.files.addAll(request.files);
      return copy;
    }
    return request;
  }
}
