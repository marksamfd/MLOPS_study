# Pet Portrait Platform - System Architecture

## Overview

This is a microservices-based platform that converts pet photos and scene descriptions into high-quality artistic portraits, which are then printed on canvas and shipped to customers.

```
User Interface
     ↓
 Web Application (FastAPI)
     ├─→ AI Service (Flask)  → Image Generation
     ├─→ Printing Service    → Fulfillment
     └─→ Persistent Storage
```

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                          User Browser                            │
│                  (Web Interface / API Client)                   │
└────────────────────────────┬────────────────────────────────────┘
                             │ HTTP/REST
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    WEB APPLICATION LAYER                         │
│                   FastAPI (Python 3.10)                          │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ Functions:                                                │   │
│  │ • Upload file endpoint                                   │   │
│  │ • Request orchestration                                  │   │
│  │ • Status tracking                                        │   │
│  │ • Error handling & logging                               │   │
│  │ • CORS support for cross-origin requests                │   │
│  │                                                          │   │
│  │ Port: 8000 (Uvicorn ASGI Server)                         │   │
│  │ Health: /health                                          │   │
│  │ Docs: /docs (Swagger), /redoc (ReDoc)                    │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                   │
└────────────┬──────────────────────────────┬──────────────────────┘
             │ JSON/HTTP                    │ JSON/HTTP
             ▼                              ▼
    ┌─────────────────────┐       ┌──────────────────────┐
    │   AI SERVICE        │       │ PRINTING SERVICE     │
    │  (Flask - Python)   │       │ (Flask - Python)     │
    │                     │       │                      │
    │ Functions:          │       │ Functions:           │
    │ • Image loading     │       │ • Order queuing      │
    │ • Preprocessing     │       │ • Status tracking    │
    │ • Portrait          │       │ • Fulfillment sim    │
    │   generation        │       │ • Shipping tracking  │
    │ • Output saving     │       │ • Order persistence  │
    │                     │       │                      │
    │ Port: 5000          │       │ Port: 5001           │
    │ Model: Stable       │       │ Storage: JSON files  │
    │ Diffusion v1.5      │       │ + In-memory DB       │
    │                     │       │                      │
    └─────────────────────┘       └──────────────────────┘
             │                              │
             ▼                              ▼
    ┌─────────────────────┐       ┌──────────────────────┐
    │  Generated Images   │       │   Order Metadata     │
    │  Docker Volume      │       │   Docker Volume      │
    │ (Persistent)        │       │  (Persistent)        │
    └─────────────────────┘       └──────────────────────┘
```

## Component Details

### 1. Web Application (FastAPI)

**Technology**: Python 3.10 + FastAPI + Uvicorn

**Key Features**:
- RESTful API for file uploads
- Service orchestration
- Request ID tracking
- Error handling with detailed messages
- CORS middleware for cross-origin requests
- Swagger UI documentation at `/docs`

**Endpoints**:
```
GET  /health              - Health check
GET  /                    - Service info
POST /upload              - Upload image/description
GET  /status/{request_id} - Get order status
GET  /orders              - List all orders (demo)
```

**Environment Variables**:
- `AI_SERVICE_URL`: AI service endpoint (default: http://ai-service:5000)
- `PRINTING_SERVICE_URL`: Printing service endpoint (default: http://printing-service:5001)

**Error Handling**:
- HTTP 400: Bad request (missing files)
- HTTP 404: Resource not found
- HTTP 500: Server error
- HTTP 503: Service unavailable (downstream service down)

**Logging**:
- Structured logging with timestamps
- INFO: Request events, orchestration
- ERROR: Service failures, exceptions
- Request/response tracking with UUIDs

### 2. AI Service (Flask)

**Technology**: Python 3.10 + Flask

**Key Features**:
- Image upload processing
- Portrait generation (Stable Diffusion simulation)
- Image format conversion and resizing
- Persistent output storage
- Graceful error handling

**Endpoints**:
```
GET  /health        - Health check
GET  /             - Service info
POST /generate      - Generate portrait from image or description
```

**Request Format**:
```json
{
  "image_path": "uploads/uuid_filename.jpg",
  "description": "A golden retriever with brown eyes"
}
```

**Response Format**:
```json
{
  "request_id": "uuid",
  "message": "Portrait generated successfully",
  "image_path": "generated_images/uuid_portrait.png",
  "model": "stable-diffusion-v1.5",
  "timestamp": "2024-01-15T10:30:00"
}
```

**Image Processing**:
- Load input image (JPEG, PNG, WebP)
- Convert to RGB
- Resize to 512x512 (model standard)
- Apply artistic filters (Gaussian blur, color enhancement)
- Save as PNG

**Storage**:
- Generated images stored in Docker volume `ai-generated-images`
- Volume mounted at `/app/generated_images` in container
- Persistent across container restarts

### 3. Printing Service (Flask)

**Technology**: Python 3.10 + Flask

**Key Features**:
- Order queuing and management
- Status tracking with simulated workflow
- Order persistence
- Shipping cost estimation
- Canvas/frame configuration options

**Endpoints**:
```
GET  /health              - Health check
GET  /                    - Service info
POST /queue               - Queue a print order
GET  /status/{request_id} - Get order status
GET  /orders              - List all orders
```

**Order Workflow Simulation**:
```
Time Elapsed    Status      Progress    Description
0-1 hour        queued      10%        Order received
1-2 hours       printing    40%        Printing on canvas
2-4 hours       packaging   70%        Framing and packaging
4-12 hours      shipped     100%       Shipped (tracking provided)
12+ hours       delivered   100%       Delivered
```

**Order Structure**:
```json
{
  "request_id": "uuid",
  "image_path": "generated_images/uuid_portrait.png",
  "status": "printing",
  "created_at": "2024-01-15T10:30:00",
  "estimated_delivery": "2024-01-22T10:30:00",
  "canvas_size": "11x14 inches",
  "frame": "Black wood frame",
  "price": 49.99,
  "progress": 40,
  "status_message": "Currently printing your portrait on canvas"
}
```

**Storage**:
- Orders stored as JSON files in Docker volume `orders`
- Volume mounted at `/app/orders` in container
- Also maintained in in-memory dictionary for fast access
- JSON format allows easy inspection and auditing

**Canvas Options**:
- 8x10 inches - $39.99
- 11x14 inches - $49.99
- 16x20 inches - $69.99

**Frame Options**:
- No frame
- Black wood frame
- Natural wood frame
- White frame

## Data Flow

### Upload & Generation Flow

```
1. User uploads pet photo via Web App
   ├─ Request: POST /upload with file
   ├─ Save: File saved to uploads/ directory
   └─ Generate: UUID assigned to track request

2. Web App calls AI Service
   ├─ Endpoint: POST /generate
   ├─ Payload: image_path, description
   └─ Waits: 300 second timeout for response

3. AI Service processes image
   ├─ Load: Read image from uploads/
   ├─ Process: Resize, convert, apply filters
   ├─ Generate: Create portrait (simulated)
   ├─ Save: Output to generated_images/
   └─ Response: Return image path and metadata

4. Web App queues order to Printing Service
   ├─ Endpoint: POST /queue
   ├─ Payload: request_id, image_path, timestamp
   └─ Response: Order ID and estimated delivery

5. Web App returns to user
   └─ Response: request_id for status tracking
```

### Status Tracking Flow

```
User requests: GET /status/{request_id}
  ↓
Web App queries Printing Service
  ├─ Endpoint: GET /status/{request_id}
  ├─ Lookup: Check in-memory orders or load from JSON
  ├─ Calculate: Time elapsed since creation
  ├─ Simulate: Update status based on time
  └─ Response: Current order status with progress
```

## Networking & Service Discovery

### Docker Network

**Network Name**: `pet-portrait-network` (custom bridge network)

**Service Hostnames** (DNS-resolved inside containers):
- `web-app` → http://web-app:8000
- `ai-service` → http://ai-service:5000
- `printing-service` → http://printing-service:5001

**External Access**:
```
localhost:8000  → Web App
localhost:5000  → AI Service  
localhost:5001  → Printing Service
```

**Networking Details**:
- Custom bridge network ensures service isolation
- Services communicate via internal hostnames
- DNS auto-discovery provided by Docker
- No need for hardcoded IP addresses

## Persistence & Storage

### Volumes

1. **ai-generated-images**
   - Purpose: Store AI-generated portraits
   - Mount Point: `/app/generated_images`
   - Persistence: Survives container restart
   - Cleanup: `docker volume rm <volume_name>`

2. **orders**
   - Purpose: Store order metadata as JSON
   - Mount Point: `/app/orders`
   - Persistence: Survives container restart
   - Format: JSON files named `{request_id}_order.json`

### Data Persistence Strategy

```
Application Layer:
  ├─ Web App: Uses file system for uploads (ephemeral)
  ├─ AI Service: Volumes for generated images (persistent)
  └─ Printing Service: Volumes for order files + in-memory DB

In Production:
  ├─ Web App Uploads: S3 / Cloud Storage
  ├─ AI Service Output: CDN / S3
  ├─ Order Data: PostgreSQL / MongoDB
  ├─ Cache: Redis
  └─ Message Queue: RabbitMQ / Kafka
```

## Scalability & High Availability

### Current Setup (Single Instance)

```
docker-compose (1 instance each)
  ├─ 1 × Web App
  ├─ 1 × AI Service
  └─ 1 × Printing Service
```

### Production Setup (Kubernetes)

```
Kubernetes Cluster
  ├─ Web App (3 replicas, load balanced)
  ├─ AI Service (2 replicas, GPU nodes)
  ├─ Printing Service (2 replicas)
  ├─ PostgreSQL (primary + replica)
  ├─ Redis (cache + session store)
  └─ RabbitMQ (message queue)
```

**Improvements**:
- Horizontal scaling
- Load balancing
- Service mesh (Istio)
- Auto-scaling based on metrics
- Rolling updates
- Multi-region deployment

## Error Handling & Resilience

### Service Failures

**AI Service Down**:
```
Web App → POST /generate → timeout
Response: 503 Service Unavailable
Recovery: Retry with exponential backoff
```

**Printing Service Down**:
```
Web App → POST /queue → timeout
Response: 500 Internal Server Error
Recovery: Manual queue investigation
```

### Timeouts

```
AI Service: 300 seconds (portrait generation can take time)
Printing Service: 30 seconds (quick response expected)
```

### Retry Strategy

- Web App: Automatic retry with exponential backoff
- Manual: Admin can retry failed requests via ID

## Security Considerations

### Current Implementation

- **CORS**: Enabled for all origins (demo)
- **Authentication**: None (demo environment)
- **Authorization**: None (demo environment)
- **Encryption**: HTTP only (demo)
- **Rate Limiting**: None

### Production Recommendations

```
├─ HTTPS/TLS encryption
├─ JWT authentication
├─ Role-based access control (RBAC)
├─ Rate limiting & throttling
├─ Input validation & sanitization
├─ SQL injection prevention
├─ CSRF protection
├─ Secrets management (vault)
├─ Audit logging
├─ Regular security scanning
└─ Penetration testing
```

## Monitoring & Observability

### Health Checks

```
Web App: GET /health (HTTP 200)
AI Service: GET /health (HTTP 200)
Printing Service: GET /health (HTTP 200)
```

### Logging

```
Service logs viewable via:
  docker-compose logs [service_name]
  docker-compose logs -f [service_name]
```

### Metrics (Future)

```
├─ Request latency
├─ Error rates
├─ Throughput
├─ Resource utilization (CPU, memory)
├─ Queue depth
├─ Portrait generation time
└─ Order completion time
```

### Monitoring Tools (Production)

```
├─ Prometheus (metrics collection)
├─ Grafana (visualization)
├─ ELK Stack (centralized logging)
├─ Jaeger (distributed tracing)
├─ DataDog / New Relic (APM)
└─ Sentry (error tracking)
```

## Cost Optimization

### Current (Docker Compose)

```
Infrastructure: Minimal
  ├─ Single machine
  ├─ Shared resources
  └─ Low cost

Services: Open source
  ├─ Python + FastAPI (free)
  ├─ Flask (free)
  ├─ Pillow (free)
  └─ Docker (free)
```

### Production (Kubernetes on Cloud)

```
Compute: EC2 / GKE / AKS instances
Storage: S3 / Cloud Storage
Database: Managed services
Cache: ElastiCache / Memorystore
Queue: Managed message brokers
CDN: CloudFront / Akamai

Optimization:
  ├─ Auto-scaling
  ├─ Spot instances
  ├─ Reserved capacity
  ├─ Caching
  └─ Content delivery optimization
```

## Development Workflow

### Local Development

```bash
# Setup
docker-compose build
docker-compose up -d

# Testing
curl http://localhost:8000/health
curl http://localhost:5000/health
curl http://localhost:5001/health

# Debugging
docker-compose logs -f web-app
docker-compose exec ai-service bash

# Changes
# Edit code → docker-compose rebuild → restart service
```

### Testing

```
Unit Tests: Fast, isolated tests per service
Integration Tests: Service-to-service communication
End-to-End Tests: Full workflow simulation
Load Tests: Performance under stress
```

### CI/CD Pipeline

```
Code Push
  ↓
Automated Tests (unit, integration, lint)
  ↓
Build Docker Images
  ↓
Push to Registry
  ↓
Deploy to Staging
  ↓
Run E2E Tests
  ↓
Manual Approval
  ↓
Deploy to Production
```

## Future Enhancements

### Features

```
├─ Real Stable Diffusion integration
├─ Style selection (watercolor, oil, etc.)
├─ Multiple portrait styles
├─ Custom canvas sizes
├─ Web-based editor for adjustments
├─ User accounts & order history
├─ Payment integration
├─ Email notifications
├─ SMS status updates
└─ Mobile app
```

### Infrastructure

```
├─ Kubernetes deployment
├─ Multi-region deployment
├─ Database (PostgreSQL/MongoDB)
├─ Cache layer (Redis)
├─ Message queue (RabbitMQ)
├─ CDN for images
├─ API Gateway
├─ Service mesh
├─ Secrets management
└─ Infrastructure as Code (Terraform)
```

### Operations

```
├─ Observability (Prometheus/Grafana)
├─ Centralized logging (ELK)
├─ Distributed tracing (Jaeger)
├─ Error tracking (Sentry)
├─ Status page
├─ Incident management
├─ On-call rotation
├─ Runbooks & playbooks
└─ Disaster recovery plan
```

## Conclusion

This architecture provides a solid foundation for a microservices-based pet portrait platform. It demonstrates:

- ✅ Service separation of concerns
- ✅ Asynchronous communication via REST
- ✅ Data persistence
- ✅ Health monitoring
- ✅ Error handling
- ✅ Scalability foundation

The system is ready to scale from this prototype to a production platform serving thousands of customers daily.
