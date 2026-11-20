@echo off
echo ========================================================
echo Setting up CampusFlow AI (Competition Edition) on Windows 11
echo ========================================================

echo [1/4] Setting up Environment Files...
if not exist server\.env copy server\.env.example server\.env
if not exist client\.env copy client\.env.example client\.env
if not exist .env copy .env.example .env

echo [2/4] Installing Server Dependencies...
cd server
call npm install
cd ..

echo [3/4] Installing Client Dependencies...
cd client
call npm install
cd ..

echo [4/4] Getting Flutter Dependencies for Mobile...
cd mobile
call flutter pub get
cd ..

echo ========================================================
echo Setup Complete! 
echo To run:
echo 1. Start MongoDB locally (MongoDB Compass).
echo 2. In terminal 1: cd server && npm run dev
echo 3. In terminal 2: cd client && npm run dev
echo 4. In terminal 3: cd mobile && flutter run
echo ========================================================
pause
