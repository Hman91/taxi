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
/// Defaults:
/// - Android emulator: `http://10.0.2.2:5000`
/// - Web (Chrome): `http://localhost:5000`
/// - Other platforms: `http://127.0.0.1:5000`
final String apiBaseUrl = () {
  const fromEnv = String.fromEnvironment('API_BASE_URL', defaultValue: '');
  if (fromEnv.isNotEmpty) return fromEnv;

  if (kIsWeb) return 'http://localhost:5000';
  if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:5000';
  return 'http://127.0.0.1:5000';
}();
