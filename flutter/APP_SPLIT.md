# Flutter App Split

This repository now contains two Flutter applications that share the same backend and database:

- `flutter/passenger_app`: passenger-only app
- `flutter/taxi_pro`: staff app (driver, b2b, owner, operator)

## Run locally

### Passenger app

```powershell
cd flutter/passenger_app
flutter pub get
flutter run -d android --dart-define=API_BASE_URL=http://192.168.1.43:5000
```

### Staff app

```powershell
cd flutter/taxi_pro
flutter pub get
flutter run -d android --dart-define=API_BASE_URL=http://192.168.1.43:5000
```

## Production builds

### Passenger app

```powershell
cd flutter/passenger_app
.\build_apk_production.ps1 -ApiBase "https://your-backend-url"
.\build_web_production.ps1 -ApiBase "https://your-backend-url"
```

### Staff app

Use existing scripts under `flutter/taxi_pro`.
