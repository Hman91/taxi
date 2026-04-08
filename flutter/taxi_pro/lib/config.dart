/// API base URL. Override at build time, e.g.:
/// `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000` (Android emulator)
/// `flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:5000`
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:5000',
);
