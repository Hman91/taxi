# Flutter Web + Google Sign-In
# - Without --no-cross-origin-isolation, `flutter run --wasm` turns on COOP/COEP (see Flutter
#   kCrossOriginIsolationHeaders: COOP same-origin breaks GSI popup close detection).
# - `dart.flutterRunAdditionalArgs` in .vscode/settings.json also passes --no-cross-origin-isolation
#   when you run from Cursor/VS Code (this script keeps the same for terminal runs).
# Optional: .\run_web.ps1 -ApiBase "http://127.0.0.1:5000"
param(
  [string]$ApiBase = "http://127.0.0.1:5000",
  [int]$WebPort = 8080
)
Set-Location $PSScriptRoot
flutter run -d chrome `
  "--dart-define=API_BASE_URL=$ApiBase" `
  --web-hostname localhost `
  --web-port $WebPort `
  --no-cross-origin-isolation
