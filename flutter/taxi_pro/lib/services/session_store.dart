import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../api/models.dart';

enum PersistedRole {
  appPassenger,
  appDriver,
  driverPin,
  owner,
  operator,
  b2b,
}

class PersistedSession {
  const PersistedSession({
    required this.role,
    this.appLogin,
    this.driverPinLogin,
    this.login,
    this.token,
  });

  final PersistedRole role;
  final AppLoginResponse? appLogin;
  final DriverPinLoginResponse? driverPinLogin;
  final LoginResponse? login;
  final String? token;
}

class SessionStore {
  static const _key = 'persisted_session_v1';

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key);
  }

  static Future<void> saveAppPassenger(AppLoginResponse r) =>
      _saveMap({'role': 'app_passenger', 'payload': _appPayload(r)});

  static Future<void> saveAppDriver(AppLoginResponse r) =>
      _saveMap({'role': 'app_driver', 'payload': _appPayload(r)});

  static Future<void> saveDriverPin(DriverPinLoginResponse r) =>
      _saveMap({'role': 'driver_pin', 'payload': _driverPinPayload(r)});

  static Future<void> saveOwnerToken(String token) =>
      _saveMap({'role': 'owner', 'payload': {'access_token': token}});

  static Future<void> saveOperatorToken(String token) =>
      _saveMap({'role': 'operator', 'payload': {'access_token': token}});

  static Future<void> saveB2b(LoginResponse r) =>
      _saveMap({'role': 'b2b', 'payload': _loginPayload(r)});

  static Future<PersistedSession?> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_key);
      if (raw == null || raw.trim().isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final m = Map<String, dynamic>.from(decoded);
      final role = (m['role'] ?? '').toString();
      final payloadAny = m['payload'];
      if (payloadAny is! Map) return null;
      final payload = Map<String, dynamic>.from(payloadAny);
      switch (role) {
        case 'app_passenger':
          return PersistedSession(
            role: PersistedRole.appPassenger,
            appLogin: AppLoginResponse(
              accessToken: (payload['access_token'] ?? '').toString(),
              role: (payload['role'] ?? 'user').toString(),
              userId: (payload['user_id'] as num?)?.toInt() ?? 0,
              preferredLanguage: payload['preferred_language'] as String?,
            ),
          );
        case 'app_driver':
          return PersistedSession(
            role: PersistedRole.appDriver,
            appLogin: AppLoginResponse(
              accessToken: (payload['access_token'] ?? '').toString(),
              role: (payload['role'] ?? 'driver').toString(),
              userId: (payload['user_id'] as num?)?.toInt() ?? 0,
              preferredLanguage: payload['preferred_language'] as String?,
            ),
          );
        case 'driver_pin':
          return PersistedSession(
            role: PersistedRole.driverPin,
            driverPinLogin: DriverPinLoginResponse(
              accessToken: (payload['access_token'] ?? '').toString(),
              role: (payload['role'] ?? 'driver').toString(),
              userId: (payload['user_id'] as num?)?.toInt() ?? 0,
              driverId: (payload['driver_id'] as num?)?.toInt(),
              driverName: (payload['driver_name'] ?? '').toString(),
              phone: (payload['phone'] ?? '').toString(),
              walletBalance:
                  (payload['wallet_balance'] as num?)?.toDouble() ?? 0.0,
              ownerCommissionRate:
                  (payload['owner_commission_rate'] as num?)?.toDouble() ?? 10.0,
              b2bCommissionRate:
                  (payload['b2b_commission_rate'] as num?)?.toDouble() ?? 5.0,
              autoDeductEnabled:
                  (payload['auto_deduct_enabled'] as bool?) ?? true,
              photoUrl: payload['photo_url'] as String?,
              carModel: payload['car_model'] as String?,
              carColor: payload['car_color'] as String?,
              currentZone: payload['current_zone'] as String?,
              preferredLanguage: payload['preferred_language'] as String?,
            ),
          );
        case 'owner':
          return PersistedSession(
            role: PersistedRole.owner,
            token: (payload['access_token'] ?? '').toString(),
          );
        case 'operator':
          return PersistedSession(
            role: PersistedRole.operator,
            token: (payload['access_token'] ?? '').toString(),
          );
        case 'b2b':
          return PersistedSession(
            role: PersistedRole.b2b,
            login: LoginResponse(
              accessToken: (payload['access_token'] ?? '').toString(),
              role: (payload['role'] ?? 'b2b').toString(),
              appAccessToken: payload['app_access_token'] as String?,
              userId: (payload['user_id'] as num?)?.toInt(),
            ),
          );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _saveMap(Map<String, dynamic> m) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode(m));
  }

  static Map<String, dynamic> _appPayload(AppLoginResponse r) => {
        'access_token': r.accessToken,
        'role': r.role,
        'user_id': r.userId,
        'preferred_language': r.preferredLanguage,
      };

  static Map<String, dynamic> _driverPinPayload(DriverPinLoginResponse r) => {
        'access_token': r.accessToken,
        'role': r.role,
        'user_id': r.userId,
        'driver_id': r.driverId,
        'driver_name': r.driverName,
        'phone': r.phone,
        'wallet_balance': r.walletBalance,
        'owner_commission_rate': r.ownerCommissionRate,
        'b2b_commission_rate': r.b2bCommissionRate,
        'auto_deduct_enabled': r.autoDeductEnabled,
        'photo_url': r.photoUrl,
        'car_model': r.carModel,
        'car_color': r.carColor,
        'current_zone': r.currentZone,
        'preferred_language': r.preferredLanguage,
      };

  static Map<String, dynamic> _loginPayload(LoginResponse r) => {
        'access_token': r.accessToken,
        'role': r.role,
        'app_access_token': r.appAccessToken,
        'user_id': r.userId,
      };
}
