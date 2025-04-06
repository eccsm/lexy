@echo off
echo Starting Flutter web app with custom server...

:: Kill any process running on port 8080 (optional)
for /f "tokens=5" %%a in ('netstat -aon ^| find ":8080"') do (
    taskkill /F /PID %%a
)

:: Start the Flutter app in debug mode
start cmd /k "flutter run -d chrome --web-hostname=localhost --web-port=8085"

:: Wait a bit for the build to complete
timeout /t 10

:: Start a second server with the CORS headers
start "" http://localhost:8080
call dart pub global run dhttpd --path build/web --headers="Cross-Origin-Opener-Policy=same-origin;Cross-Origin-Embedder-Policy=require-corp"

pause