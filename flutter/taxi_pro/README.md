# taxi_pro

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Test against a deployed API without rebuilding APK

Use `flutter run` on a USB device or emulator with the same
`API_BASE_URL` you use for release builds (hot reload works; no APK step):

```bash
cd flutter/taxi_pro
flutter run --dart-define=API_BASE_URL=https://your-api.onrender.com
```

- **Physical phone**: use your LAN IP for a dev machine API, or the public HTTPS URL for staging/production.
- **Android emulator**: for a Flask API on the host PC, prefer `http://10.0.2.2:5000` as documented in the repo root `README.md`.

Release APK (distribution):

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://your-api.onrender.com
```
