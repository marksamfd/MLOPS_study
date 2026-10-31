@echo off
REM Setup script to create Docker images for Pet Portrait Platform

echo Creating directory structure...
mkdir web-app 2>nul
mkdir ai-service 2>nul
mkdir printing-service 2>nul

REM Web App Dockerfile
(
echo FROM python:3.10-slim
echo WORKDIR /app
echo RUN apt-get update ^&^& apt-get install -y curl ^&^& rm -rf /var/lib/apt/lists/*
echo COPY requirements.txt .
echo RUN pip install --no-cache-dir -r requirements.txt
echo COPY app.py .
echo EXPOSE 8000
echo HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
echo     CMD curl -f http://localhost:8000/health ^|^| exit 1
echo CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
) > web-app\Dockerfile

REM Web App requirements
(
echo fastapi==0.104.1
echo uvicorn==0.24.0
echo python-multipart==0.0.6
echo httpx==0.25.2
echo pydantic==2.5.0
echo pillow==10.1.0
) > web-app\requirements.txt

REM Web App Python code
if exist web-app-app.py (
  copy /Y web-app-app.py web-app\app.py >nul
) else (
  echo ERROR: web-app-app.py not found in current folder.
  echo        Cannot create web-app\app.py
)

echo Web App files created...

REM AI Service Dockerfile
(
echo FROM python:3.10-slim
echo WORKDIR /app
echo RUN apt-get update ^&^& apt-get install -y curl ^&^& rm -rf /var/lib/apt/lists/*
echo COPY requirements.txt .
echo RUN pip install --no-cache-dir -r requirements.txt
echo COPY app.py .
echo RUN mkdir -p generated_images
echo EXPOSE 5000
echo HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
echo     CMD curl -f http://localhost:5000/health ^|^| exit 1
echo CMD ["python", "app.py"]
) > ai-service\Dockerfile

REM AI Service requirements
(
echo flask==3.0.0
echo flask-cors==4.0.0
echo pillow==10.1.0
echo requests==2.31.0
) > ai-service\requirements.txt

REM AI Service Python code
if exist ai-service-app.py (
  copy /Y ai-service-app.py ai-service\app.py >nul
) else (
  echo ERROR: ai-service-app.py not found in current folder.
  echo        Cannot create ai-service\app.py
)

echo AI Service files created...

REM Printing Service Dockerfile
(
echo FROM python:3.10-slim
echo WORKDIR /app
echo RUN apt-get update ^&^& apt-get install -y curl ^&^& rm -rf /var/lib/apt/lists/*
echo COPY requirements.txt .
echo RUN pip install --no-cache-dir -r requirements.txt
echo COPY app.py .
echo RUN mkdir -p orders
echo EXPOSE 5001
echo HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
echo     CMD curl -f http://localhost:5001/health ^|^| exit 1
echo CMD ["python", "app.py"]
) > printing-service\Dockerfile

REM Printing Service requirements
(
echo flask==3.0.0
echo flask-cors==4.0.0
echo pillow==10.1.0
echo requests==2.31.0
) > printing-service\requirements.txt

REM Printing Service Python code
if exist printing-service-app.py (
  copy /Y printing-service-app.py printing-service\app.py >nul
) else (
  echo ERROR: printing-service-app.py not found in current folder.
  echo        Cannot create printing-service\app.py
)

echo Printing Service files created...
echo.
echo ✅ Docker image setup complete!
echo.
echo Services created:
echo   📱 Web App (FastAPI)        - Port 8000
echo   🧠 AI Service (Flask)       - Port 5000
echo   🖨️  Printing Service (Flask) - Port 5001
echo.
echo To build and run:
echo   docker-compose build
echo   docker-compose up
