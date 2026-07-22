@echo off
echo ===================================================
echo   TradeMentor: Building & Deploying Web (Firebase)
echo ===================================================
cd "%~dp0..\mobile_app"
call flutter pub get
call flutter build web --release
echo.
echo   Deploying build files from mobile_app/build/web/ to Firebase Hosting...
cd "%~dp0..\web_app"
call firebase deploy --only hosting
echo ===================================================
echo   Deployment completed!
echo ===================================================
pause
