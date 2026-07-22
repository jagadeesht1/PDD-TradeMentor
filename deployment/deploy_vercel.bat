@echo off
echo ===================================================
echo   TradeMentor: Building & Deploying Web (Vercel)
echo ===================================================
cd "%~dp0..\mobile_app"
call flutter pub get
call flutter build web --release
echo.
echo   Copying build folder to web_app directory...
xcopy /s /e /y "%~dp0..\mobile_app\build\web" "%~dp0..\web_app\public"
echo.
echo   Deploying via Vercel CLI...
cd "%~dp0..\web_app"
call vercel --prod
echo ===================================================
echo   Vercel Deployment Completed!
echo ===================================================
pause
