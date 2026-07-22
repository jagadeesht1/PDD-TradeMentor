@echo off
echo ===================================================
echo   TradeMentor: Compiling Android Release APK
echo ===================================================
cd "%~dp0..\mobile_app"
call flutter pub get
call flutter build apk --release
echo ===================================================
echo   Build finished. Release APK can be found under:
echo   mobile_app\build\app\outputs\flutter-apk\app-release.apk
echo ===================================================
pause
