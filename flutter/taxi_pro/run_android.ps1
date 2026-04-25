# Run taxi_pro on Android Emulator.
# API defaults to http://10.0.2.2:5000 — run your backend on the PC on port 5000.
#
# Android Studio: open flutter/taxi_pro, Device Manager (phone icon) > start an AVD, green Run.
# Or from this folder after starting an emulator:
#   flutter run -d android
# Cold start (launch AVD then app):
#   .\run_android.ps1 -StartEmulator
param(
  [switch]$StartEmulator,
  [string]$EmulatorId = "Pixel_Tablet_API_35"
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

flutter run -d android
