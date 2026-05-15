import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../services/session_store.dart';
import 'models.dart';

/// In-memory bearer tokens; persisted via [SessionStore].
class AuthTokenStore {
  AuthTokenStore._();
  static final AuthTokenStore instance = AuthTokenStore._();

  String? accessToken;
  String? refreshToken;
  String? b2bRoleAccessToken;
  PersistedRole? _role;
  DateTime? _accessIssuedAt;
  Timer? _proactiveRefreshTimer;

  final StreamController<String?> _accessController =
      StreamController<String?>.broadcast();
  Stream<String?> get accessTokenStream => _accessController.stream;

  void clear() {
    accessToken = null;
    refreshToken = null;
    b2bRoleAccessToken = null;
    _role = null;
    _accessIssuedAt = null;
    _proactiveRefreshTimer?.cancel();
    _proactiveRefreshTimer = null;
    _accessController.add(null);
  }

  String? bearerForApi({bool b2bRoleOnly = false}) {
    if (b2bRoleOnly) {
      final r = b2bRoleAccessToken;
      if (r != null && r.isNotEmpty) return r;
    }
    final a = accessToken;
    return (a != null && a.isNotEmpty) ? a : null;
  }

  String? resolveBearer(String? explicit, {bool b2bRoleOnly = false}) {
    final fromStore = bearerForApi(b2bRoleOnly: b2bRoleOnly);
    if (fromStore != null && fromStore.isNotEmpty) return fromStore;
    final e = (explicit ?? '').trim();
    return e.isEmpty ? null : e;
  }

  void applyLoginBundle(Map<String, dynamic> json, PersistedRole role) {
    _role = role;
    if (json.containsKey('refresh_token')) {
      final rt = (json['refresh_token'] ?? '').toString().trim();
      refreshToken = rt.isEmpty ? null : rt;
    }
    final app = (json['app_access_token'] ?? '').toString().trim();
    final access = (json['access_token'] ?? '').toString().trim();
    if (app.isNotEmpty) {
      b2bRoleAccessToken = access.isNotEmpty ? access : null;
      accessToken = app;
    } else {
      b2bRoleAccessToken = null;
      accessToken = access.isNotEmpty ? access : null;
    }
    _accessIssuedAt = DateTime.now();
    _accessController.add(accessToken);
    _scheduleProactiveRefresh();
  }

  void applyFromAppLogin(AppLoginResponse r, PersistedRole role) {
    applyLoginBundle({
      'access_token': r.accessToken,
      'refresh_token': r.refreshToken,
    }, role);
  }

  void applyFromDriverPin(DriverPinLoginResponse r) {
    applyLoginBundle({
      'access_token': r.accessToken,
      'refresh_token': r.refreshToken,
    }, PersistedRole.driverPin);
  }

  void applyFromLegacyLogin(LoginResponse r, PersistedRole role) {
    applyLoginBundle({
      'access_token': r.accessToken,
      'refresh_token': r.refreshToken,
      'app_access_token': r.appAccessToken,
    }, role);
  }

  void applyFromPersisted(PersistedSession s) {
    _role = s.role;
    refreshToken = null;
    b2bRoleAccessToken = null;
    accessToken = null;
    switch (s.role) {
      case PersistedRole.appPassenger:
      case PersistedRole.appDriver:
        final a = s.appLogin;
        if (a != null) {
          accessToken = a.accessToken;
          refreshToken = a.refreshToken;
        }
        break;
      case PersistedRole.driverPin:
        final d = s.driverPinLogin;
        if (d != null) {
          accessToken = d.accessToken;
          refreshToken = d.refreshToken;
        }
        break;
      case PersistedRole.owner:
      case PersistedRole.operator:
        accessToken = s.token;
        break;
      case PersistedRole.b2b:
        final l = s.login;
        if (l != null) {
          accessToken = l.appAccessToken ?? l.accessToken;
          b2bRoleAccessToken = l.appAccessToken != null ? l.accessToken : null;
          refreshToken = l.refreshToken;
        }
        break;
    }
    _accessIssuedAt = DateTime.now();
    _accessController.add(accessToken);
    _scheduleProactiveRefresh();
  }

  Future<void> persistTokens() async {
    final role = _role;
    if (role == null) return;
    await SessionStore.updateTokens(
      role: role,
      accessToken: accessToken ?? '',
      refreshToken: refreshToken,
      appAccessToken: b2bRoleAccessToken != null ? accessToken : null,
      b2bRoleOnlyAccessToken: b2bRoleAccessToken,
    );
  }

  void _scheduleProactiveRefresh() {
    _proactiveRefreshTimer?.cancel();
    final rt = refreshToken;
    if (rt == null || rt.isEmpty) return;
    _proactiveRefreshTimer = Timer.periodic(const Duration(minutes: 10), (_) {
      unawaited(ensureFreshAccess());
    });
  }

  Future<bool> ensureFreshAccess() async {
    final rt = refreshToken;
    if (rt == null || rt.isEmpty) return false;
    final issued = _accessIssuedAt;
    if (issued != null &&
        DateTime.now().difference(issued) < const Duration(minutes: 12)) {
      return true;
    }
    return refreshSession();
  }

  Future<bool> refreshSession() async {
    final rt = refreshToken;
    if (rt == null || rt.isEmpty) return false;
    final uri = Uri.parse(apiBaseUrl).resolve('/api/auth/refresh');
    final r = await http.Client().post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh_token': rt}),
    );
    if (r.statusCode != 200) return false;
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    final role = _role ?? PersistedRole.appPassenger;
    applyLoginBundle(body, role);
    await persistTokens();
    return true;
  }
}

class TaxiSessionExpiredException implements Exception {
  @override
  String toString() => 'TaxiSessionExpiredException';
}
