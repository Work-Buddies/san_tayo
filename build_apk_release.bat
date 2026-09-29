@echo off
cd /d C:\Users\Kai\Desktop\san_tayo\frontend

if not exist "android\key.properties" (
    echo key.properties not found in frontend\android.
    echo The build would fall back to the debug key, so stopping here.
    pause
    exit /b 1
)

echo Running flutter pub get...
call flutter pub get
if errorlevel 1 (
    echo pub get failed.
    pause
    exit /b 1
)

echo Building release APK...
call flutter build apk --release
if errorlevel 1 (
    echo Build failed.
    pause
    exit /b 1
)

echo.
echo Done. Output:
echo %CD%\build\app\outputs\flutter-apk\app-release.apk
pause