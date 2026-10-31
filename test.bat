@echo off
REM Test script for Pet Portrait Platform

echo 🧪 Testing Pet Portrait Platform...
echo.

echo ⏳ Waiting for services to start (30 seconds)...
timeout /t 30 /nobreak

REM Test Web App
echo 📱 Testing Web App...
curl -s http://localhost:8000/health
echo.
echo Web App Info:
curl -s http://localhost:8000/

REM Test AI Service
echo.
echo 🧠 Testing AI Service...
curl -s http://localhost:5000/health
echo.
echo AI Service Info:
curl -s http://localhost:5000/

REM Test Printing Service
echo.
echo 🖨️  Testing Printing Service...
curl -s http://localhost:5001/health
echo.
echo Printing Service Info:
curl -s http://localhost:5001/

echo.
echo ✅ All services tested!
echo.
echo Next steps:
echo 1. Test file upload: curl -X POST -F "file=@test.jpg" http://localhost:8000/upload
echo 2. Check status: curl http://localhost:8000/status/REQUEST_ID
echo 3. View logs: docker-compose logs -f
