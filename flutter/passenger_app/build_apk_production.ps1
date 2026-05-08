param(
  [Parameter(Mandatory = $true)][string]$ApiBase
)

Set-Location $PSScriptRoot
flutter pub get
flutter build apk --release --dart-define=API_BASE_URL=$ApiBase
