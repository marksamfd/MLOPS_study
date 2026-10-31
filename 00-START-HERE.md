# 📦 Pet Portrait Platform - Complete Docker Setup

## ✅ What's Included

This complete Docker-based system includes three microservices that work together to create AI-powered pet portraits and ship them as physical canvas prints.

### Services Included

#### 🌐 **Web Application (FastAPI)** - Port 8000
- **Purpose**: Main user interface and API orchestrator
- **Technology**: Python 3.10 + FastAPI + Uvicorn
- **Features**:
  - File upload endpoint
  - Service orchestration
  - Order status tracking
  - Interactive API docs (Swagger/ReDoc)
- **Entry Point**: `http://localhost:8000`
- **Files**: 
  - `web-app/Dockerfile`
  - `web-app/requirements.txt`
  - `web-app/app.py`

#### 🧠 **AI Service** - Port 5000
- **Purpose**: Generate artistic portraits from images
- **Technology**: Python 3.10 + Flask + Pillow
- **Features**:
  - Image processing and resizing
  - Artistic filter application
  - Stable Diffusion simulation
  - Persistent image storage
- **Entry Point**: `http://localhost:5000`
- **Files**:
  - `ai-service/Dockerfile`
  - `ai-service/requirements.txt`
  - `ai-service/app.py`

#### 🖨️ **Printing Service** - Port 5001
- **Purpose**: Handle order fulfillment and shipping
- **Technology**: Python 3.10 + Flask
- **Features**:
  - Order queuing
  - Status tracking (queued → printing → packaging → shipped)
  - Simulated fulfillment workflow
  - Order persistence
- **Entry Point**: `http://localhost:5001`
- **Files**:
  - `printing-service/Dockerfile`
  - `printing-service/requirements.txt`
  - `printing-service/app.py`

---

## 📋 Complete File Manifest

### Docker Configuration
```
docker-compose.yml          Multi-container orchestration (all services)
.dockerignore              Docker build ignore rules
```

### Service Code
```
web-app-app.py             Standalone Web App code (for reference)
ai-service-app.py          Standalone AI Service code (for reference)
printing-service-app.py    Standalone Printing Service code (for reference)
```

### Setup Scripts
```
setup.sh                   Bash script to create service directories
setup.bat                  Windows batch script for setup
```

### Testing
```
test.sh                    Bash test/verification script
test.bat                   Windows test script
```

### Documentation
```
README.md                  Getting started and overview
QUICKSTART.md             5-minute setup guide
ARCHITECTURE.md           Detailed system architecture (15KB+)
API.md                    Complete API reference (14KB+)
```

### Utilities
```
Makefile                   Convenient command shortcuts
```

---

## 🚀 Getting Started

### Step 1: One-Time Setup

**Option A: Bash (macOS, Linux, WSL2)**
```bash
bash setup.sh
```

**Option B: Windows CMD**
```cmd
setup.bat
```

This creates three directories with Dockerfiles and Python code:
- `web-app/`
- `ai-service/`
- `printing-service/`

### Step 2: Build Docker Images

```bash
docker-compose build
```

Output: 3 Docker images created
- `final-study_web-app:latest`
- `final-study_ai-service:latest`
- `final-study_printing-service:latest`

### Step 3: Start Services

```bash
docker-compose up -d
```

Output: 3 containers running
- Web App listening on port 8000
- AI Service listening on port 5000
- Printing Service listening on port 5001

### Step 4: Verify

```bash
# Check all services are healthy
curl http://localhost:8000/health
curl http://localhost:5000/health
curl http://localhost:5001/health
```

Expected response:
```json
{"status": "healthy", "service": "web-app"}
```

---

## 💡 Common Usage Patterns

### Upload a Pet Photo

```bash
curl -X POST \
  -F "file=@my_pet.jpg" \
  -F "description=My golden retriever" \
  http://localhost:8000/upload
```

Response:
```json
{
  "request_id": "abc123-def456-ghi789",
  "message": "Portrait generated and queued for printing",
  "generated_image": "generated_images/abc123-def456-ghi789_portrait.png"
}
```

### Check Order Status

```bash
curl http://localhost:8000/status/abc123-def456-ghi789
```

Response shows progression:
- 🔴 **Queued** (0-1 hour): Waiting to print
- 🟠 **Printing** (1-2 hours): On the canvas
- 🟡 **Packaging** (2-4 hours): Being framed
- 🟢 **Shipped** (4+ hours): On the way!

### View Logs

```bash
docker-compose logs -f web-app
docker-compose logs -f ai-service
docker-compose logs -f printing-service
```

### Stop Services

```bash
docker-compose down
```

---

## 📊 System Architecture

```
┌─────────────────────────────────────────────────┐
│            User (Browser/Client)                │
└──────────────────┬──────────────────────────────┘
                   │ HTTP/REST
                   ▼
        ┌──────────────────────┐
        │   Web App (8000)     │
        │ - Upload endpoint    │
        │ - Orchestration      │
        │ - Status tracking    │
        └────┬─────────────────┘
             │
        ┌────┴────────────┬──────────────┐
        │                 │              │
        ▼                 ▼              ▼
    ┌────────┐      ┌──────────┐   ┌────────────┐
    │ AI Svc │      │ Printing │   │  Network   │
    │(5000)  │      │  Svc(5001)   │Discovery  │
    └────────┘      └──────────┘   └────────────┘
        │                 │
        ▼                 ▼
   [Generated]       [Order Data]
   [Images Vol]      [Vol]
```

---

## 🔍 Key Concepts

### Microservices
Each service (Web, AI, Printing) runs independently:
- ✅ Can be scaled separately
- ✅ Can be updated independently
- ✅ Failure isolation
- ✅ Different tech stacks possible

### Docker Network
Services communicate via internal Docker network:
- Service names resolve to IPs automatically
- No hardcoded IPs needed
- Isolated from external network

### Persistent Volumes
Data survives container restarts:
- Generated images stored in `ai-generated-images` volume
- Order metadata stored in `orders` volume

### Health Checks
Each service exposes `/health` endpoint:
- Used by orchestration
- Used for monitoring
- Returns service status

---

## 📈 From Demo to Production

Current Setup:
```
Single Machine
├─ 1 Web App
├─ 1 AI Service
└─ 1 Printing Service
```

Production Setup:
```
Kubernetes Cluster
├─ Web App (3 replicas)
├─ AI Service (2 replicas, GPU nodes)
├─ Printing Service (2 replicas)
├─ PostgreSQL (primary + replica)
├─ Redis (cache)
├─ RabbitMQ (message queue)
├─ Nginx (load balancer)
└─ ELK Stack (logging)
```

---

## 🎯 Technology Stack

| Layer | Technology | Version |
|-------|-----------|---------|
| **Web Framework** | FastAPI | 0.104.1 |
| **Web Server** | Uvicorn | 0.24.0 |
| **API Framework** | Flask | 3.0.0 |
| **Image Processing** | Pillow | 10.1.0 |
| **Runtime** | Python | 3.10 |
| **Orchestration** | Docker Compose | 3.9 |
| **Container Engine** | Docker | Latest |

---

## 💾 Storage Details

### Volumes Created
```
ai-generated-images/
  └── [uuid]_portrait.png

orders/
  └── [uuid]_order.json
```

### View Volume Contents
```bash
# List volumes
docker volume ls

# Inspect volume
docker volume inspect final-study_ai-generated-images

# Access volume data
docker run -it --rm -v final-study_ai-generated-images:/data \
  busybox ls -la /data
```

---

## 🔒 Security Notes

**Current** (Demo):
- ✋ No authentication
- ✋ No HTTPS
- ✋ CORS open to all

**Production** (Recommended):
- 🔒 JWT authentication
- 🔒 HTTPS/TLS encryption
- 🔒 Rate limiting
- 🔒 Input validation
- 🔒 Secrets management
- 🔒 Audit logging

---

## 📞 Getting Help

### Logs
```bash
docker-compose logs [service_name]
docker-compose logs -f          # Follow all logs
```

### Check Running Containers
```bash
docker-compose ps
docker ps
```

### Verify Network
```bash
docker network ls
docker network inspect final-study_pet-portrait-network
```

### Interactive Testing
```bash
docker-compose exec web-app bash
docker-compose exec ai-service bash
docker-compose exec printing-service bash
```

---

## 🚀 Next Steps

After getting this running:

1. **Explore the Code**: Review the Python files in each service directory
2. **Try the APIs**: Use curl or Postman to test endpoints
3. **Read Documentation**: Check ARCHITECTURE.md for deeper understanding
4. **Modify Services**: Try changing canvas sizes, adding new endpoints
5. **Integrate Real AI**: Replace image generation with actual Stable Diffusion
6. **Add Database**: Swap in PostgreSQL for persistent order storage
7. **Deploy**: Use Kubernetes manifests for production deployment

---

## 📚 Documentation Map

- **Quick Start**: QUICKSTART.md (this file)
- **Overview**: README.md (features and setup)
- **Architecture**: ARCHITECTURE.md (system design, 15KB+)
- **API Reference**: API.md (endpoints and examples, 14KB+)

---

## ✨ Features Demonstrated

✅ Microservices architecture
✅ Container orchestration (Docker Compose)
✅ Service discovery
✅ Volume persistence
✅ Health checks
✅ Error handling
✅ Logging
✅ REST APIs
✅ Async processing
✅ Inter-service communication

---

## 🎓 Learning Resources

- **Docker**: https://docs.docker.com/
- **Docker Compose**: https://docs.docker.com/compose/
- **FastAPI**: https://fastapi.tiangolo.com/
- **Flask**: https://flask.palletsprojects.com/
- **Microservices**: https://microservices.io/

---

## 📝 Changelog

### v1.0.0 (January 2024)
- Initial release
- 3-service microservices architecture
- Complete Docker Compose setup
- Full documentation
- API reference

---

**Status**: ✅ Ready to Run
**Maintenance**: Active
**Last Updated**: January 2024
**Version**: 1.0.0

---

## 🎉 You're All Set!

Run these commands and you'll have a fully functional pet portrait platform:

```bash
bash setup.sh              # or setup.bat on Windows
docker-compose build
docker-compose up -d
docker-compose logs -f     # Watch the services start
```

Then test it:
```bash
curl -X POST \
  -F "file=@test.jpg" \
  http://localhost:8000/upload
```

Welcome to microservices! 🚀
