# Run taxi_pro on Android (emulator or USB phone).
#
# Emulator: API defaults to http://10.0.2.2:5000 (see lib/config.dart). Backend on PC :5000.
#
# Physical phone (USB): use -UsbPhone (adb reverse + 127.0.0.1) or -ApiBase with your PC LAN IP:
#   .\run_android.ps1 -UsbPhone
#   .\run_android.ps1 -ApiBase "http://192.168.1.42:5000"
#
# Android Studio: open flutter/taxi_pro, pick device, Run.
# Or from this folder after starting an emulator:
#   flutter run -d android
# Cold start (launch AVD then app):
#   .\run_android.ps1 -StartEmulator
param(
  [switch]$StartEmulator,
  [string]$EmulatorId = "Pixel_Tablet_API_35",
  [switch]$UsbPhone,
  [string]$ApiBase = ""
)
Set-Location $PSScriptRoot
$adb = Join-Path $env:LOCALAPPDATA "Android\Sdk\platform-tools\adb.exe"

if ($StartEmulator) {
  Write-Host "Launching $EmulatorId ..." -ForegroundColor Cyan
  flutter emulators --launch $EmulatorId
  if (Test-Path $adb) {
    Write-Host "Waiting for adb device ..." -ForegroundColor Cyan
    & $adb wait-for-device
    Start-Sleep -Seconds 25
  } else {
    Write-Host "Wait until the emulator shows the home screen, then press Enter." -ForegroundColor Yellow
    Read-Host
  }
}

$flutterArgs = @("run", "-d", "android")
if ($UsbPhone) {
  if (Test-Path $adb) {
    Write-Host "adb reverse tcp:5000 -> host:5000 (USB phone)" -ForegroundColor Cyan
    & $adb reverse tcp:5000 tcp:5000
  } else {
    Write-Host "adb.exe not found; run: adb reverse tcp:5000 tcp:5000" -ForegroundColor Yellow
  }
  $flutterArgs += "--dart-define=API_BASE_URL=http://127.0.0.1:5000"
} elseif ($ApiBase -ne "") {
  $flutterArgs += "--dart-define=API_BASE_URL=$ApiBase"
}
& flutter @flutterArgs
