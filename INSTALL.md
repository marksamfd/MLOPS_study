# Pet Portrait Platform - Installation & Setup Guide

## 📋 System Requirements

### Minimum Requirements
- **OS**: Windows 10/11, macOS 10.15+, Linux (Ubuntu 18.04+)
- **RAM**: 4 GB (8 GB recommended)
- **Disk**: 5 GB free space
- **CPU**: 2 cores minimum (4+ recommended)

### Software Requirements
- **Docker Desktop**: 4.0+
- **Docker Compose**: 1.29+
- **Git**: (optional, for version control)
- **Curl**: (for testing, usually pre-installed)

---

## 🔧 Installation Steps

### Step 1: Install Docker

#### Windows 10/11
1. Download Docker Desktop: https://www.docker.com/products/docker-desktop
2. Run installer, follow on-screen instructions
3. Restart computer
4. Verify installation:
```bash
docker --version
docker-compose --version
```

#### macOS
1. Download Docker Desktop: https://www.docker.com/products/docker-desktop
2. Drag to Applications folder
3. Launch Docker from Applications
4. Complete setup wizard
5. Verify:
```bash
docker --version
docker-compose --version
```

#### Linux (Ubuntu/Debian)
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.0.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify
docker --version
docker-compose --version

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker
```

---

## 🚀 Quick Start (Choose One)

### Method 1: Automated Setup Script (Recommended)

#### On Windows (Command Prompt or PowerShell)
```cmd
cd /d D:\Files\Work\MLOPS\final-study
setup.bat
docker-compose build
docker-compose up -d
```

#### On macOS/Linux (Terminal)
```bash
cd /path/to/final-study
bash setup.sh
docker-compose build
docker-compose up -d
```

### Method 2: Using Makefile

If you have `make` installed:

```bash
cd /path/to/final-study
make setup
make build
make up
make health
```

### Method 3: Manual Setup

```bash
# 1. Copy service app files to respective directories
# (Already provided as *-app.py files)

# 2. Build images
docker-compose build

# 3. Start services
docker-compose up -d

# 4. Check status
docker-compose ps
```

---

## ✅ Verification

### Check Docker Installation
```bash
docker --version        # Should show Docker version
docker ps              # Should show running containers (initially empty)
```

### Start Services
```bash
docker-compose up -d
```

### Verify Services Running
```bash
# Check containers
docker-compose ps

# Expected output:
# NAME                    STATUS
# final-study_web-app       Up 2 minutes
# final-study_ai-service    Up 2 minutes
# final-study_printing-      Up 2 minutes
```

### Health Checks
```bash
# All should return HTTP 200
curl http://localhost:8000/health
curl http://localhost:5000/health
curl http://localhost:5001/health

# Check response
# {"status": "healthy", "service": "web-app"}
```

---

## 📁 What Gets Created

After running setup and docker-compose:

### Directory Structure
```
final-study/
├── web-app/
│   ├── Dockerfile
│   ├── requirements.txt
│   └── app.py
├── ai-service/
│   ├── Dockerfile
│   ├── requirements.txt
│   └── app.py
├── printing-service/
│   ├── Dockerfile
│   ├── requirements.txt
│   └── app.py
└── docker-compose.yml
```

### Docker Images Created
```
final-study_web-app:latest           (~400 MB)
final-study_ai-service:latest        (~400 MB)
final-study_printing-service:latest  (~400 MB)
python:3.10-slim                     (~150 MB) [base image]
```

### Docker Volumes Created
```
final-study_ai-generated-images     (stores generated portraits)
final-study_orders                  (stores order metadata)
```

### Docker Network Created
```
final-study_pet-portrait-network    (custom bridge network)
```

---

## 🧪 Test the Installation

### 1. Basic Health Check
```bash
curl http://localhost:8000/
```

Should return:
```json
{
  "service": "Pet Portrait Generator - Web Application",
  "version": "1.0.0",
  "endpoints": { ... }
}
```

### 2. Upload Test Image
```bash
# Download a test image or use your own
curl -X POST \
  -F "file=@test.jpg" \
  http://localhost:8000/upload
```

Should return:
```json
{
  "request_id": "some-uuid-here",
  "message": "Portrait generated and queued for printing"
}
```

### 3. Check Status
```bash
curl http://localhost:8000/status/some-uuid-here
```

Should show:
```json
{
  "status": "queued",  // or printing, packaging, shipped
  "progress": 10,
  ...
}
```

### 4. View Interactive Docs
Open browser to: http://localhost:8000/docs

You should see Swagger UI with interactive API testing.

---

## 🛠️ Configuration

### Change Ports

Edit `docker-compose.yml`:

```yaml
services:
  web-app:
    ports:
      - "8001:8000"  # Changed from 8000 to 8001

  ai-service:
    ports:
      - "5002:5000"  # Changed from 5000 to 5002

  printing-service:
    ports:
      - "5003:5001"  # Changed from 5001 to 5003
```

Then restart:
```bash
docker-compose restart
```

### Change Service URLs

Edit `docker-compose.yml` environment section:

```yaml
web-app:
  environment:
    - AI_SERVICE_URL=http://custom-ai:5000
    - PRINTING_SERVICE_URL=http://custom-print:5001
```

---

## 📊 Resource Usage

### Typical Usage Per Service

| Service | CPU | Memory | Disk |
|---------|-----|--------|------|
| Web App | 50-100m | 50-100 MB | 1 GB |
| AI Service | 100-200m | 100-200 MB | 2 GB |
| Printing Service | 50m | 50 MB | 1 GB |
| **Total** | **200-350m** | **200-350 MB** | **4 GB** |

### Monitor Resource Usage

```bash
# Real-time stats
docker stats

# Stop individual service
docker-compose stop web-app

# Pause service (without stopping)
docker-compose pause web-app
docker-compose unpause web-app
```

---

## 🔄 Common Tasks

### View Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f web-app

# Last 100 lines
docker-compose logs --tail=100 web-app

# Since specific time
docker-compose logs --since 2024-01-15 web-app
```

### Update Service Code

```bash
# Edit code in service directory
# Then rebuild and restart
docker-compose build web-app
docker-compose up -d web-app
```

### Access Container Shell
```bash
docker-compose exec web-app bash

# Now you're inside container
# ls, cat, python, etc.
exit
```

### Clean Up

```bash
# Stop services
docker-compose down

# Remove volumes
docker-compose down -v

# Clean Docker system
docker system prune -a

# Remove unused images
docker image prune -a
```

---

## 🐛 Troubleshooting

### Docker daemon not running
```bash
# Windows: Restart Docker Desktop
# macOS: Click Docker icon > Restart
# Linux: sudo systemctl start docker
```

### Port already in use
```bash
# Windows
netstat -ano | findstr :8000

# macOS/Linux
lsof -i :8000

# Kill process or change port in docker-compose.yml
```

### Container won't start
```bash
# Check logs
docker-compose logs web-app

# Rebuild
docker-compose build --no-cache web-app

# Try again
docker-compose up -d
```

### Out of disk space
```bash
docker system df              # Check usage
docker system prune -a        # Clean unused
docker volume prune           # Clean unused volumes
```

### Services can't communicate
```bash
# Check network
docker network inspect final-study_pet-portrait-network

# Verify DNS
docker-compose exec web-app nslookup ai-service

# Restart networking
docker-compose down
docker-compose up -d
```

### Database/Volume permission errors
```bash
# On Linux, might need permissions
sudo chown -R $USER:$USER ~/final-study

# Or use sudo with docker commands
sudo docker-compose up -d
```

---

## 📈 Scaling

### Single Instance (Current)
```bash
docker-compose up -d
```

### Multiple Instances (via Docker-in-Docker)
```bash
# Scale web-app to 3 instances
docker-compose up -d --scale web-app=3
```

### Production Scaling (Kubernetes)
```bash
# Install kubectl
# Install helm
# Deploy Kubernetes manifests:
kubectl apply -f k8s/deployment.yaml
```

---

## 🔐 Security

### Enable HTTPS
```bash
# Update docker-compose.yml with SSL certificates
# Rebuild services
docker-compose build --no-cache
docker-compose up -d
```

### Add Authentication
```python
# Update app.py with JWT authentication
# Rebuild
docker-compose build web-app
docker-compose up -d
```

### Secure Volumes
```bash
# Restrict volume permissions (Linux)
sudo chmod 700 /var/lib/docker/volumes/*/
```

---

## 📚 Next Steps

1. ✅ Install Docker
2. ✅ Run setup script
3. ✅ Start services
4. ✅ Test endpoints
5. 📖 Read documentation (README.md, ARCHITECTURE.md, API.md)
6. 🔧 Explore code in service directories
7. 🚀 Deploy to production
8. 📊 Monitor and scale

---

## 📞 Support

### Documentation
- **Quick Start**: QUICKSTART.md
- **Overview**: README.md
- **Architecture**: ARCHITECTURE.md
- **API Reference**: API.md

### External Resources
- Docker Docs: https://docs.docker.com/
- Docker Compose: https://docs.docker.com/compose/
- FastAPI: https://fastapi.tiangolo.com/
- Flask: https://flask.palletsprojects.com/

### Common Issues
1. Docker not installed → Install from docker.com
2. Port already in use → Change port in docker-compose.yml
3. Out of memory → Increase Docker memory limit
4. Network issues → Check docker network and DNS

---

## ✨ Success Indicators

✅ Docker installed and running
✅ Services up and healthy
✅ Port 8000 responding
✅ API endpoints working
✅ Can upload files
✅ Can check status
✅ Logs showing activity

---

## 🎉 You're Ready!

Once verified, you have:
- ✅ 3 running microservices
- ✅ Complete API
- ✅ Data persistence
- ✅ Health monitoring
- ✅ Full documentation

Start by uploading an image:
```bash
curl -X POST \
  -F "file=@photo.jpg" \
  http://localhost:8000/upload
```

Then track the order:
```bash
curl http://localhost:8000/status/{request_id}
```

Enjoy your pet portrait platform! 🚀

---

**Installation Guide v1.0**
Last Updated: January 2024
