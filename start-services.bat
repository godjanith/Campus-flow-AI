@echo off
setlocal enabledelayedexpansion
title CampusFlow AI - Dual Real-Time System Orchestrator

echo ============================================================
echo   CampusFlow AI - Presidency University Integrated System
echo   Synchronizing Web Command Console and Mobile Flutter App
echo ============================================================
echo.

set ROOT_DIR=%~dp0
set DATA_DIR=%ROOT_DIR%data\db

:: 1. Ensure Local Data Directory Exists
if not exist "%DATA_DIR%" (
    echo [*] Creating MongoDB data directory at data\db...
    mkdir "%DATA_DIR%"
)

:: 2. Launch Local MongoDB Daemon (Port 27017)
echo [*] Checking and launching MongoDB daemon...
tasklist /FI "IMAGENAME eq mongod.exe" 2>NUL | find /I /N "mongod.exe">NUL
if "%ERRORLEVEL%"=="0" (
    echo [OK] MongoDB is already running on port 27017.
) else (
    echo [*] Starting mongod on 127.0.0.1:27017...
    start "CampusFlow MongoDB" /B "C:\Program Files\MongoDB\Server\8.2\bin\mongod.exe" --dbpath "%DATA_DIR%" --bind_ip 127.0.0.1 --port 27017
    timeout /t 2 /nobreak >NUL
)

:: 3. Configure Android USB ADB Reverse Proxy (if physical device connected)
echo [*] Configuring ADB reverse port 5000 for physical Android device...
adb reverse tcp:5000 tcp:5000 >NUL 2>&1
if "%ERRORLEVEL%"=="0" (
    echo [OK] ADB Reverse Active: Phone can reach backend at 127.0.0.1:5000 over USB.
) else (
    echo [INFO] No USB ADB device connected. Phone can connect over Wi-Fi (172.17.83.174:5000).
)

:: 4. Free port 5000 if an older server instance is running
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :5000 ^| findstr LISTENING 2^>NUL') do (
    echo [*] Terminating stale background server on port 5000 (PID: %%a)...
    taskkill /F /PID %%a >NUL 2>&1
)

:: 5. Start Core Node.js Express + Socket.IO Server
echo [*] Starting CampusFlow Core Server on port 5000...
echo [OK] Hosting Web Dashboard at: http://localhost:5000
echo [OK] Hosting LAN Dashboard at: http://172.17.83.174:5000
echo [OK] Real-time Mobile Socket connected to port 5000
echo.
cd /d "%ROOT_DIR%server"
node server.js
pause
