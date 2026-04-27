param(
  [string]$ApiBase = "",
  [switch]$NoClean
)
Set-Location $PSScriptRoot
$defines = @()
if ($ApiBase -ne "") {
  $defines += "--dart-define=API_BASE_URL=$ApiBase"
} elseif (Test-Path "api_base.production.json") {
  $defines += "--dart-define-from-file=api_base.production.json"
} else {
  Write-Error "Set -ApiBase OR create api_base.production.json (same as build_web_production.ps1)"
  exit 1
}
Write-Host "Building APK (release)..." -ForegroundColor Cyan
Write-Host "Example: -ApiBase https://your-api.onrender.com  (https only, no :0, no trailing slash)" -ForegroundColor DarkGray
if (-not $NoClean) {
  Write-Host "Running flutter clean (use -NoClean to skip)..." -ForegroundColor DarkGray
  flutter clean
}
flutter build apk --release @defines
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Host "Output: build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Green
