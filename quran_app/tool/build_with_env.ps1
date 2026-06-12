$ErrorActionPreference = 'Stop'
Set-Location 'F:\My_VC_Projects\quran_app'
flutter build apk --debug --no-pub --dart-define=QURAN_MANIFEST_BASE=https://10.0.2.2:8443/v1 2>&1 | Select-Object -Last 5
