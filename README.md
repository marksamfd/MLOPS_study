# Pet Portrait Platform - Docker Setup

A complete containerized system for generating AI-powered artistic pet portraits and shipping them as printed canvas.

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      USER (Web Browser)                      │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│        WEB APPLICATION (FastAPI)                             │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ • File upload endpoint                               │   │
│  │ • Orchestrates workflow between AI and Printing      │   │
│  │ • Order status tracking                              │   │
│  │ Port: 8000                                           │   │
│  └──────────────────────────────────────────────────────┘   │
└────────┬──────────────────────┬──────────────────────┬──────┘
         │                      │                      │
         ▼                      ▼                      ▼
    ┌────────────────┐  ┌──────────────────┐  ┌───────────────────┐
    │  AI SERVICE    │  │ PRINTING SERVICE │  │   DOCKER NETWORK  │
    │    (Flask)     │  │     (Flask)      │  │  pet-portrait-net │
    │                │  │                  │  │                   │
    │ • Portrait     │  │ • Order queuing  │  │ Service discovery │
    │   generation   │  │ • Status tracking│  │ & communication   │
    │ • Image        │  │ • Shipment       │  │                   │
    │   processing   │  │   simulation     │  │                   │
    │ Port: 5000     │  │ Port: 5001       │  │                   │
    └────────────────┘  └──────────────────┘  └───────────────────┘
         │                      │
         ▼                      ▼
    ┌────────────────┐  ┌──────────────────┐
    │ Generated      │  │    Order Files   │
    │ Images Vol.    │  │    Volume        │
    └────────────────┘  └──────────────────┘
```

## Components

### 1. **Web Application (FastAPI)** 📱
- **Purpose**: Main user interface and orchestrator
- **Port**: 8000
- **Endpoints**:
  - `GET /` - Service info
  - `GET /health` - Health check
  - `POST /upload` - Upload pet photo or scene description
  - `GET /status/{request_id}` - Check order status
- **Responsibilities**:
  - Accepts file uploads and descriptions
  - Calls AI service for portrait generation
  - Queues orders to printing service
  - Provides status updates to users

### 2. **AI Service (Flask)** 🧠
- **Purpose**: Generate artistic portraits using AI (Stable Diffusion simulation)
- **Port**: 5000
- **Endpoints**:
  - `GET /` - Service info
  - `GET /health` - Health check
  - `POST /generate` - Generate portrait from image or description
- **Responsibilities**:
  - Processes uploaded images
  - Generates artistic portraits
  - Saves generated images to persistent volume

### 3. **Printing Service (Flask)** 🖨️
- **Purpose**: Handle printing and shipping logistics
- **Port**: 5001
- **Endpoints**:
  - `GET /` - Service info
  - `GET /health` - Health check
  - `POST /queue` - Queue an order for printing
  - `GET /status/{request_id}` - Get order status
- **Responsibilities**:
  - Queues orders for printing
  - Tracks order progress
  - Simulates printing/packaging/shipping workflow
  - Stores order metadata

## Quick Start

### Option 1: Using Shell Script (Linux/Mac)
```bash
chmod +x setup.sh
./setup.sh
docker-compose build
docker-compose up
```

### Option 2: Using Batch Script (Windows)
```cmd
setup.bat
docker-compose build
docker-compose up
```

### Option 3: Manual Docker Commands
```bash
# Build all services
docker-compose build

# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

## Workflow Example

### 1. **Upload Phase**
```bash
# User uploads a pet photo
curl -X POST -F "file=@puppy.jpg" http://localhost:8000/upload
```

### 2. **AI Processing Phase**
- Web app sends image to AI service
- AI service generates artistic portrait
- Saves portrait to persistent volume

### 3. **Printing Queue Phase**
- Web app sends generated portrait to printing service
- Printing service queues the order
- Returns order ID and estimated delivery date

### 4. **Order Tracking Phase**
```bash
# Check order status
curl http://localhost:8000/status/order-123-456
```

**Status progression**:
- `queued` (0-1 hours)
- `printing` (1-2 hours)
- `packaging` (2-4 hours)
- `shipped` (4+ hours)

## Project Structure

```
final-study/
├── docker-compose.yml          # Multi-container orchestration
├── setup.sh                     # Linux/Mac setup script
├── setup.bat                    # Windows setup script
├── README.md                    # This file
│
├── web-app/                     # FastAPI Web Application
│   ├── Dockerfile
│   ├── requirements.txt
│   └── app.py
│
├── ai-service/                  # AI Portrait Generation
│   ├── Dockerfile
│   ├── requirements.txt
│   └── app.py
│
└── printing-service/            # Printing & Shipping
    ├── Dockerfile
    ├── requirements.txt
    └── app.py
```

## Configuration

### Environment Variables
Services communicate via environment variables set in `docker-compose.yml`:

| Variable | Default | Service |
|----------|---------|---------|
| `AI_SERVICE_URL` | `http://ai-service:5000` | web-app |
| `PRINTING_SERVICE_URL` | `http://printing-service:5001` | web-app |
| `FLASK_ENV` | `production` | ai-service, printing-service |

### Volumes
- **ai-generated-images**: Persists AI-generated portrait images
- **orders**: Persists order metadata and tracking info

## Health Checks

All services include health checks:

```bash
# Check web app health
curl http://localhost:8000/health

# Check AI service health
curl http://localhost:5000/health

# Check printing service health
curl http://localhost:5001/health
```

## API Examples

### Upload & Generate Portrait
```bash
curl -X POST \
  -F "file=@pet_photo.jpg" \
  -F "description=A golden retriever" \
  http://localhost:8000/upload

# Response:
# {
#   "request_id": "123e4567-e89b-12d3-a456-426614174000",
#   "message": "Portrait generated and queued for printing",
#   "generated_image": "generated_images/123e4567-e89b-12d3-a456-426614174000_portrait.png"
# }
```

### Check Order Status
```bash
curl http://localhost:8000/status/123e4567-e89b-12d3-a456-426614174000

# Response:
# {
#   "request_id": "123e4567-e89b-12d3-a456-426614174000",
#   "image_path": "generated_images/123e4567-e89b-12d3-a456-426614174000_portrait.png",
#   "status": "printing",
#   "created_at": "2024-01-15T10:30:00",
#   "estimated_delivery": "2024-01-22T10:30:00",
#   "canvas_size": "11x14 inches",
#   "frame": "Black wood frame"
# }
```

## Technology Stack

| Component | Technology | Version |
|-----------|-----------|---------|
| Web App | FastAPI | 0.104.1 |
| Web Server | Uvicorn | 0.24.0 |
| AI Service | Flask | 3.0.0 |
| Image Processing | Pillow | 10.1.0 |
| Python Runtime | Python | 3.10 |
| Orchestration | Docker Compose | 3.9 |

## Development & Debugging

### View Container Logs
```bash
docker-compose logs web-app
docker-compose logs ai-service
docker-compose logs printing-service
```

### Access Container Shell
```bash
docker-compose exec web-app bash
docker-compose exec ai-service bash
docker-compose exec printing-service bash
```

### Rebuild Single Service
```bash
docker-compose build web-app
docker-compose up web-app
```

## Extending the System

### Add a Web UI (Streamlit)
```bash
# Create streamlit/ directory with Dockerfile
# Update docker-compose.yml with streamlit service
# Run: docker-compose up streamlit
```

### Integrate Real Stable Diffusion API
Replace the AI service image generation with actual API calls to:
- Hugging Face Stable Diffusion
- OpenAI DALL-E
- Replicate API

### Add Payment Processing
Integrate Stripe or PayPal into the web app for orders.

### Database Integration
Replace in-memory order storage with:
- PostgreSQL
- MongoDB
- Redis

## Troubleshooting

### Services not communicating
```bash
# Check docker network
docker network ls
docker network inspect final-study_pet-portrait-network

# Verify DNS resolution
docker-compose exec web-app nslookup ai-service
```

### Port conflicts
Change ports in `docker-compose.yml`:
```yaml
ports:
  - "8001:8000"  # Changed from 8000
```

### Out of disk space
Clean up Docker resources:
```bash
docker system prune -a
```

## Production Deployment

For production, consider:
1. **Kubernetes**: Use Helm charts for orchestration
2. **Load Balancing**: Add Nginx/HAProxy for multiple web instances
3. **Database**: Use managed PostgreSQL for order persistence
4. **Message Queue**: Use Redis/RabbitMQ for async processing
5. **CDN**: Serve generated images from CloudFront/S3
6. **Monitoring**: Add Prometheus + Grafana for observability
7. **Logging**: Centralize logs with ELK/Loki stack

## License

This is a sample project for educational purposes.

## Support

For issues or questions, refer to:
- Docker documentation: https://docs.docker.com/
- FastAPI docs: https://fastapi.tiangolo.com/
- Flask docs: https://flask.palletsprojects.com/
