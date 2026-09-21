@echo off
cd /d C:\Users\Kai\Desktop\san_tayo\frontend

echo Running flutter pub get...
call flutter pub get
if errorlevel 1 (
    echo pub get failed.
    pause
    exit /b 1
)

echo Building debug APK...
call flutter build apk --debug
if errorlevel 1 (
    echo Build failed.
    pause
    exit /b 1
)

echo Done.
pause