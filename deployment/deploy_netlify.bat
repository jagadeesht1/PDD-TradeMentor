@echo off
echo ===================================================
echo   TradeMentor: Building & Deploying Web (Netlify)
echo ===================================================
cd "%~dp0..\mobile_app"
call flutter pub get
call flutter build web --release
echo.
echo   Deploying web build via Netlify CLI...
cd "%~dp0..\web_app"
call netlify deploy --prod --dir="%~dp0..\mobile_app\build\web"
echo ===================================================
echo   Netlify Deployment Completed!
echo ===================================================
pause
