import 'package:flutter/foundation.dart';

/// Google OAuth **Web application** client ID (same as backend `GOOGLE_OAUTH_CLIENT_ID`).
/// Used as `serverClientId` on Android/iOS so the ID token audience matches backend verification.
const String googleOAuthWebClientId =
    '962065998165-o2v10060s3l65ve7n8leee7hn28ddh6d.apps.googleusercontent.com';

/// API base URL.
///
/// Override at build time with:
/// `flutter run --dart-define=API_BASE_URL=http://your-host:5000`
///
/// For production HTTPS (Render) use a host only, e.g. `https://api.onrender.com` — not `:443` and
/// **never** `:0` (bad CI/shell can produce that and breaks Socket.IO on Android).
///
/// Defaults:
/// - Android emulator: `http://10.0.2.2:5000`
/// - Android physical device: **never** use `10.0.2.2` — pass `--dart-define=API_BASE_URL=...`:
///   your PC LAN IP (`http://192.168.x.x:5000` on same Wi‑Fi), or after
///   `adb reverse tcp:5000 tcp:5000` use `http://127.0.0.1:5000`.
/// - Web (Chrome): `http://localhost:5000`
/// - Other platforms: `http://127.0.0.1:5000`
final String apiBaseUrl = _computeApiBaseUrl();

String _computeApiBaseUrl() {
  const fromEnv = String.fromEnvironment('API_BASE_URL', defaultValue: '');
  if (fromEnv.isNotEmpty) {
    return normalizeApiBaseUrl(fromEnv);
  }

  if (kIsWeb) return 'http://localhost:5000';
  if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:5000';
  return 'http://127.0.0.1:5000';
}

/// Normalizes the API / Socket.IO origin. Call this for any string passed to [ChatSocketService].
///
/// * Removes an invalid **`:0`** port (e.g. bad `--dart-define` or CI). The `socket_io_client`
///   Engine would otherwise keep `port=0` and skip the default 443/80, breaking Android.
/// * Trims and strips a trailing `/`.
String normalizeApiBaseUrl(String raw) {
  var t = raw.trim();
  if (t.isEmpty) return t;
  // Strip mistaken ":0" before path/query/end (invalid port; engine.io would keep it).
  t = t.replaceFirst(RegExp(r':0(?=[/?#]|$)'), '');
  var u = Uri.tryParse(t);
  if (u == null) return t;
  if (u.hasPort && u.port == 0) {
    t = Uri(
      scheme: u.scheme,
      userInfo: u.userInfo,
      host: u.host,
      path: u.path,
      query: u.hasQuery ? u.query : null,
      fragment: u.hasFragment ? u.fragment : null,
    ).toString();
  }
  if (t.endsWith('/') && t.length > 1) {
    t = t.substring(0, t.length - 1);
  }
  return t;
}
