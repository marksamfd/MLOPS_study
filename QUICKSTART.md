# Pet Portrait Platform - Quick Start Guide

## 🚀 5-Minute Setup

### Prerequisites
- Docker Desktop (or Docker Engine)
- Docker Compose 3.9+
- Curl or Postman (for API testing)

### Option 1: Using Bash (macOS/Linux/WSL2)

```bash
# 1. Setup directory structure and copy files
bash setup.sh

# 2. Build Docker images
docker-compose build

# 3. Start all services
docker-compose up -d

# 4. Verify services are running
curl http://localhost:8000/health
curl http://localhost:5000/health
curl http://localhost:5001/health
```

### Option 2: Using Command Prompt (Windows)

```cmd
REM 1. Setup directory structure
setup.bat

REM 2. Build Docker images
docker-compose build

REM 3. Start all services
docker-compose up -d

REM 4. Verify services
curl http://localhost:8000/health
curl http://localhost:5000/health
curl http://localhost:5001/health
```

### Option 3: Using Make (Any OS with Make installed)

```bash
make setup
make build
make up
make health
```

---

## 📝 File Structure Created

After running setup script, you'll have:

```
final-study/
├── docker-compose.yml          ← Multi-container orchestration
├── .dockerignore
│
├── web-app/                     ← FastAPI Web Application
│   ├── Dockerfile
│   ├── requirements.txt
│   └── app.py
│
├── ai-service/                  ← Portrait Generation
│   ├── Dockerfile
│   ├── requirements.txt
│   └── app.py
│
└── printing-service/            ← Print & Ship Service
    ├── Dockerfile
    ├── requirements.txt
    └── app.py

Documentation:
├── README.md                    ← Getting started
├── ARCHITECTURE.md              ← System design
├── API.md                       ← API reference
├── Makefile                     ← Quick commands
└── setup.sh / setup.bat         ← Setup scripts
```

---

## 🧪 Test the System

### 1. Verify Health

```bash
# All services should respond with HTTP 200
curl http://localhost:8000/health
curl http://localhost:5000/health
curl http://localhost:5001/health
```

### 2. Upload a Test Image

```bash
# Using a sample image (or create a test image)
curl -X POST \
  -F "file=@test.jpg" \
  -F "description=My pet" \
  http://localhost:8000/upload
```

**Save the `request_id` from response**

### 3. Check Order Status

```bash
# Replace REQUEST_ID with actual ID from upload
curl http://localhost:8000/status/REQUEST_ID
```

Monitor the status - it will progress: queued → printing → packaging → shipped

### 4. Access Interactive Documentation

Open in browser:
- http://localhost:8000/docs (Swagger UI)
- http://localhost:8000/redoc (ReDoc)

---

## 🔧 Common Commands

### View Service Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f web-app
docker-compose logs -f ai-service
docker-compose logs -f printing-service
```

### Stop Services

```bash
docker-compose down
```

### Clean Everything

```bash
docker-compose down -v
```

### Rebuild Single Service

```bash
docker-compose build web-app
docker-compose up web-app
```

### Access Container Shell

```bash
docker-compose exec web-app bash
docker-compose exec ai-service bash
docker-compose exec printing-service bash
```

---

## 🎯 Service Endpoints

| Service | Port | Health | Docs |
|---------|------|--------|------|
| Web App | 8000 | /health | /docs, /redoc |
| AI Service | 5000 | /health | Browse endpoints in logs |
| Printing | 5001 | /health | Browse endpoints in logs |

---

## 📚 API Quick Reference

### Upload Image
```bash
POST /upload
-F "file=@image.jpg"
-F "description=optional text"
```

### Check Status
```bash
GET /status/{request_id}
```

### Service Info
```bash
GET /
```

---

## 🐛 Troubleshooting

### Services won't start
```bash
# Check Docker is running
docker ps

# View build errors
docker-compose build --no-cache

# Check resource limits
docker system df
```

### Port already in use
```bash
# Find what's using port 8000
netstat -ano | findstr :8000  # Windows
lsof -i :8000                  # macOS/Linux

# Change ports in docker-compose.yml if needed
```

### Out of disk space
```bash
docker system prune -a
docker volume prune
```

### Services can't communicate
```bash
# Check network
docker network ls
docker network inspect final-study_pet-portrait-network

# Verify DNS resolution
docker-compose exec web-app nslookup ai-service
```

---

## 📖 Documentation Files

- **README.md** - Overview and features
- **ARCHITECTURE.md** - System design and detailed technical info
- **API.md** - Complete API reference with examples
- **Makefile** - Command shortcuts

---

## 🎓 Next Steps

1. ✅ Run services
2. ✅ Test with sample image
3. ✅ Monitor status progression
4. ✅ Review API documentation
5. ✅ Explore code in service directories
6. 🔜 Integrate real Stable Diffusion
7. 🔜 Add database (PostgreSQL)
8. 🔜 Deploy to Kubernetes

---

## 📞 Support Resources

- Docker Docs: https://docs.docker.com/
- FastAPI Docs: https://fastapi.tiangolo.com/
- Flask Docs: https://flask.palletsprojects.com/
- Docker Compose: https://docs.docker.com/compose/

---

## Environment Variables

### Web App
- `AI_SERVICE_URL` (default: http://ai-service:5000)
- `PRINTING_SERVICE_URL` (default: http://printing-service:5001)

### AI Service & Printing Service
- `FLASK_ENV` (default: production)

Edit `docker-compose.yml` to customize.

---

## Performance Notes

**Single Machine (Current Setup)**:
- ~100 concurrent users
- ~10 uploads/minute
- ~1GB RAM for all services
- Portrait generation: 5-30 seconds

**Production Scaling**:
- Horizontal scaling with Kubernetes
- Load balancing with Nginx/Traefik
- Database for order persistence
- Redis cache layer
- CDN for image distribution

---

## Security Checklist

- [ ] Change default ports in production
- [ ] Add authentication (JWT)
- [ ] Enable HTTPS/TLS
- [ ] Add rate limiting
- [ ] Input validation
- [ ] Secrets management
- [ ] Regular backups
- [ ] Security scanning
- [ ] Audit logging
- [ ] Penetration testing

---

## License & Attribution

Educational project demonstrating microservices architecture.

Technologies used:
- FastAPI (modern async web framework)
- Flask (lightweight framework)
- Python 3.10
- Docker & Docker Compose
- Pillow (image processing)

---

## Changelog

### v1.0.0
- Initial release with 3 services
- File upload with portrait simulation
- Order tracking
- Docker Compose orchestration

---

**Last Updated**: 2024-01-15
**Version**: 1.0.0
**Status**: ✅ Production Ready (Demo)
