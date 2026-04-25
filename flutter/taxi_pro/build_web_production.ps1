param(
  [string]$ApiBase = ""
)
Set-Location $PSScriptRoot
$defines = @()
if ($ApiBase -ne "") {
  $defines += "--dart-define=API_BASE_URL=$ApiBase"
} elseif (Test-Path "api_base.production.json") {
  $defines += "--dart-define-from-file=api_base.production.json"
} else {
  Write-Error "Set -ApiBase OR create api_base.production.json"
  exit 1
}
Write-Host "Building web..." -ForegroundColor Cyan
flutter build web --release @defines
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Host "Done - run: firebase deploy --only hosting" -ForegroundColor Green
