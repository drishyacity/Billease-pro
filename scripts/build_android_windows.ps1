param(
  [switch]$Android,
  [switch]$Windows
)

Write-Host "Cleaning..."
flutter clean

if ($Android) {
  Write-Host "Building Android APK (release)..."
  flutter build apk --release
}

if ($Windows) {
  Write-Host "Building Windows MSIX (release)..."
  flutter build windows --release
  flutter pub run msix:create
}

Write-Host "Done."


