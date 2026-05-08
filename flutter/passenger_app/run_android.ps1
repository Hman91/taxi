# Run passenger_app on Android (emulator or USB phone).
param(
  [switch]$StartEmulator,
  [string]$EmulatorId = "Pixel_Tablet_API_35",
  [switch]$UsbPhone,
  [string]$ApiBase = ""
)
Set-Location $PSScriptRoot
$adb = Join-Path $env:LOCALAPPDATA "Android\Sdk\platform-tools\adb.exe"

if ($StartEmulator) {
  flutter emulators --launch $EmulatorId
  if (Test-Path $adb) {
    & $adb wait-for-device
    Start-Sleep -Seconds 20
  }
}

$flutterArgs = @("run", "-d", "android")
if ($UsbPhone) {
  if (Test-Path $adb) {
    & $adb reverse tcp:5000 tcp:5000
  }
  $flutterArgs += "--dart-define=API_BASE_URL=http://127.0.0.1:5000"
} elseif ($ApiBase -ne "") {
  $flutterArgs += "--dart-define=API_BASE_URL=$ApiBase"
}
& flutter @flutterArgs
