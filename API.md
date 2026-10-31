# Pet Portrait Platform - API Documentation

## Base URLs

- **Web App**: `http://localhost:8000`
- **AI Service**: `http://localhost:5000`
- **Printing Service**: `http://localhost:5001`

---

## Web Application API (FastAPI)

### Health Check

```http
GET /health
```

**Response** (200 OK):
```json
{
  "status": "healthy",
  "service": "web-app",
  "timestamp": "2024-01-15T10:30:00.123456"
}
```

---

### Upload Image for Portrait Generation

```http
POST /upload
Content-Type: multipart/form-data

file: <binary image data>
description: <optional string>
```

**Parameters**:
- `file` (required): Image file (JPEG, PNG, WebP)
- `description` (optional): Text description of pet/scene

**Response** (201 Created):
```json
{
  "request_id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
  "message": "Portrait generated and queued for printing",
  "generated_image": "generated_images/f47ac10b-58cc-4372-a567-0e02b2c3d479_portrait.png",
  "filename": "puppy.jpg",
  "timestamp": "2024-01-15T10:30:00.123456"
}
```

**Possible Responses**:
- `201 Created`: Success
- `400 Bad Request`: No file provided
- `500 Internal Server Error`: Processing failed
- `503 Service Unavailable`: AI or Printing service down

**Example with cURL**:
```bash
curl -X POST \
  -F "file=@puppy.jpg" \
  -F "description=Golden retriever in the park" \
  http://localhost:8000/upload
```

**Example with Python Requests**:
```python
import requests

with open('puppy.jpg', 'rb') as f:
    files = {'file': f}
    data = {'description': 'Golden retriever'}
    response = requests.post('http://localhost:8000/upload', files=files, data=data)
    
request_id = response.json()['request_id']
```

---

### Check Order Status

```http
GET /status/{request_id}
```

**Path Parameters**:
- `request_id` (required): UUID from upload response

**Response** (200 OK):
```json
{
  "request_id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
  "image_path": "generated_images/f47ac10b-58cc-4372-a567-0e02b2c3d479_portrait.png",
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

**Status Values**:
- `queued` (0-1 hour): Order received, waiting to print
- `printing` (1-2 hours): Currently printing on canvas
- `packaging` (2-4 hours): Framing and packaging
- `shipped` (4-12 hours): Shipped! Has tracking number
- `delivered` (12+ hours): Delivered to address

**Possible Responses**:
- `200 OK`: Order found and status returned
- `404 Not Found`: Order ID does not exist
- `503 Service Unavailable`: Printing service unavailable

**Example with cURL**:
```bash
curl http://localhost:8000/status/f47ac10b-58cc-4372-a567-0e02b2c3d479
```

---

### List Orders (Demo)

```http
GET /orders
```

**Response** (200 OK):
```json
{
  "total_uploads": 3,
  "files": [
    "f47ac10b-58cc-4372-a567-0e02b2c3d479_puppy.jpg",
    "a1b2c3d4-e5f6-4789-0abc-def012345678_cat.png"
  ]
}
```

---

### Service Info

```http
GET /
```

**Response** (200 OK):
```json
{
  "service": "Pet Portrait Generator - Web Application",
  "version": "1.0.0",
  "description": "Main API for uploading pet photos and managing portrait orders",
  "endpoints": {
    "documentation": "/docs",
    "health": "/health (GET)",
    "upload": "/upload (POST)",
    "status": "/status/{request_id} (GET)",
    "orders": "/orders (GET)"
  },
  "ai_service": "http://ai-service:5000",
  "printing_service": "http://printing-service:5001"
}
```

---

## AI Service API (Flask)

### Health Check

```http
GET /health
```

**Response** (200 OK):
```json
{
  "status": "healthy",
  "service": "ai-service",
  "timestamp": "2024-01-15T10:30:00.123456"
}
```

---

### Generate Portrait

```http
POST /generate
Content-Type: application/json

{
  "image_path": "uploads/f47ac10b-58cc-4372-a567-0e02b2c3d479_puppy.jpg",
  "description": "Golden retriever playing in the park"
}
```

**Request Body**:
```json
{
  "image_path": "string (path to input image)",
  "description": "string (optional description)"
}
```

**Response** (200 OK):
```json
{
  "request_id": "a1b2c3d4-e5f6-4789-0abc-def012345678",
  "message": "Portrait generated successfully",
  "image_path": "generated_images/a1b2c3d4-e5f6-4789-0abc-def012345678_portrait.png",
  "model": "stable-diffusion-v1.5",
  "canvas_size": "512x512",
  "timestamp": "2024-01-15T10:30:00.123456"
}
```

**Possible Responses**:
- `200 OK`: Portrait generated successfully
- `400 Bad Request`: Missing required parameters
- `500 Internal Server Error`: Generation failed

**Example with cURL**:
```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "image_path": "uploads/puppy.jpg",
    "description": "Golden retriever"
  }' \
  http://localhost:5000/generate
```

---

### Service Info

```http
GET /
```

**Response** (200 OK):
```json
{
  "service": "AI Portrait Generation Service",
  "version": "1.0.0",
  "description": "Generates artistic portraits using Stable Diffusion",
  "models": ["stable-diffusion-v1.5"],
  "supported_formats": ["jpg", "jpeg", "png", "webp"],
  "output_size": "512x512",
  "endpoints": {
    "health": "/health (GET)",
    "generate": "/generate (POST)",
    "root": "/ (GET)"
  }
}
```

---

## Printing Service API (Flask)

### Health Check

```http
GET /health
```

**Response** (200 OK):
```json
{
  "status": "healthy",
  "service": "printing-service",
  "timestamp": "2024-01-15T10:30:00.123456",
  "total_orders": 42
}
```

---

### Queue Order for Printing

```http
POST /queue
Content-Type: application/json

{
  "request_id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
  "image_path": "generated_images/f47ac10b-58cc-4372-a567-0e02b2c3d479_portrait.png",
  "timestamp": "2024-01-15T10:30:00.123456"
}
```

**Request Body**:
```json
{
  "request_id": "string (UUID)",
  "image_path": "string (path to portrait)",
  "timestamp": "string (ISO 8601)"
}
```

**Response** (200 OK):
```json
{
  "message": "Order queued for printing and shipping",
  "order_id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
  "status": "queued",
  "estimated_delivery": "2024-01-22T10:30:00",
  "canvas_size": "11x14 inches",
  "price": 49.99
}
```

**Possible Responses**:
- `200 OK`: Order queued successfully
- `400 Bad Request`: Missing request_id or image_path
- `500 Internal Server Error`: Queueing failed

---

### Get Order Status

```http
GET /status/{request_id}
```

**Path Parameters**:
- `request_id` (required): UUID of the order

**Response** (200 OK):
```json
{
  "request_id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
  "image_path": "generated_images/f47ac10b-58cc-4372-a567-0e02b2c3d479_portrait.png",
  "status": "printing",
  "status_message": "Currently printing your portrait on canvas",
  "progress": 40,
  "created_at": "2024-01-15T10:30:00",
  "estimated_delivery": "2024-01-22T10:30:00",
  "canvas_size": "11x14 inches",
  "frame": "Black wood frame",
  "price": 49.99,
  "shipping_address": null
}
```

**Status Progression**:

| Time Elapsed | Status    | Progress | Description |
|--------------|-----------|----------|-------------|
| < 1 hour     | queued    | 10%      | Order received and queued |
| 1-2 hours    | printing  | 40%      | Printing on canvas |
| 2-4 hours    | packaging | 70%      | Framing and packaging |
| 4-12 hours   | shipped   | 100%     | Shipped with tracking |
| 12+ hours    | delivered | 100%     | Delivered |

**Possible Responses**:
- `200 OK`: Order found
- `404 Not Found`: Order does not exist
- `500 Internal Server Error`: Status check failed

---

### List All Orders (Admin)

```http
GET /orders
```

**Response** (200 OK):
```json
{
  "total_orders": 3,
  "orders": [
    {
      "request_id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
      "image_path": "generated_images/f47ac10b-58cc-4372-a567-0e02b2c3d479_portrait.png",
      "status": "shipped",
      "created_at": "2024-01-15T10:30:00",
      "estimated_delivery": "2024-01-22T10:30:00",
      "canvas_size": "11x14 inches",
      "frame": "Black wood frame",
      "price": 49.99
    }
  ]
}
```

---

### Service Info

```http
GET /
```

**Response** (200 OK):
```json
{
  "service": "Printing & Shipping Service",
  "version": "1.0.0",
  "description": "Handles printing, framing, and shipping of canvas portraits",
  "features": [
    "Order queuing and tracking",
    "Canvas printing simulation",
    "Shipping status updates",
    "Order persistence"
  ],
  "canvas_options": [
    {"size": "8x10 inches", "price": 39.99},
    {"size": "11x14 inches", "price": 49.99},
    {"size": "16x20 inches", "price": 69.99}
  ],
  "frame_options": [
    "No frame",
    "Black wood frame",
    "Natural wood frame",
    "White frame"
  ],
  "endpoints": {
    "health": "/health (GET)",
    "queue": "/queue (POST)",
    "status": "/status/<request_id> (GET)",
    "orders": "/orders (GET)"
  }
}
```

---

## Complete Workflow Example

### 1. Upload Image

```bash
curl -X POST \
  -F "file=@my_pet.jpg" \
  -F "description=My fluffy cat" \
  http://localhost:8000/upload
```

**Response**:
```json
{
  "request_id": "abc123-def456-ghi789",
  "message": "Portrait generated and queued for printing",
  "generated_image": "generated_images/abc123-def456-ghi789_portrait.png"
}
```

### 2. Poll Status (Repeat)

```bash
curl http://localhost:8000/status/abc123-def456-ghi789
```

**Response (1st check - Queued)**:
```json
{
  "status": "queued",
  "progress": 10,
  "estimated_delivery": "2024-01-22T10:30:00"
}
```

**Response (2nd check - Printing)**:
```json
{
  "status": "printing",
  "progress": 40,
  "status_message": "Currently printing your portrait on canvas"
}
```

**Response (3rd check - Packaging)**:
```json
{
  "status": "packaging",
  "progress": 70,
  "status_message": "Framing and packaging"
}
```

**Response (4th check - Shipped)**:
```json
{
  "status": "shipped",
  "progress": 100,
  "tracking_number": "TRACK123"
}
```

---

## Error Responses

### Common Error Codes

| Code | Message | Cause |
|------|---------|-------|
| 400 | Bad Request | Missing/invalid parameters |
| 404 | Not Found | Resource doesn't exist |
| 500 | Internal Server Error | Server-side failure |
| 503 | Service Unavailable | Downstream service down |

### Example Error Response

```json
{
  "error": "Order not found",
  "request_id": "abc123-def456-ghi789"
}
```

---

## Rate Limiting

Currently not implemented. In production, recommended limits:

```
Web App Upload: 10 requests/minute per IP
Status Checks: 100 requests/minute per IP
AI Generation: 5 concurrent jobs
```

---

## Authentication & Authorization

Currently not implemented. In production:

```
Authentication: JWT tokens
Authorization: Role-based access control (RBAC)
Scopes:
  - user:upload     - Can upload images
  - user:status     - Can check order status
  - admin:orders    - Can list all orders
  - admin:analytics - Can view analytics
```

---

## Response Headers

All responses include:

```
Content-Type: application/json
X-Request-ID: <uuid>
X-Response-Time: <milliseconds>
```

---

## Swagger/OpenAPI Documentation

Access interactive API docs:

- **Web App**: http://localhost:8000/docs (Swagger UI)
- **Web App**: http://localhost:8000/redoc (ReDoc)

---

## SDK Examples

### JavaScript/Node.js

```javascript
const axios = require('axios');
const FormData = require('form-data');
const fs = require('fs');

async function uploadPortrait() {
  const formData = new FormData();
  formData.append('file', fs.createReadStream('pet.jpg'));
  formData.append('description', 'My pet');
  
  const response = await axios.post(
    'http://localhost:8000/upload',
    formData,
    { headers: formData.getHeaders() }
  );
  
  return response.data.request_id;
}

async function checkStatus(requestId) {
  const response = await axios.get(
    `http://localhost:8000/status/${requestId}`
  );
  return response.data;
}
```

### Python

```python
import requests
from pathlib import Path

def upload_portrait(image_path: str, description: str = None) -> str:
    with open(image_path, 'rb') as f:
        files = {'file': f}
        data = {'description': description}
        response = requests.post(
            'http://localhost:8000/upload',
            files=files,
            data=data
        )
    return response.json()['request_id']

def check_status(request_id: str) -> dict:
    response = requests.get(
        f'http://localhost:8000/status/{request_id}'
    )
    return response.json()

# Usage
request_id = upload_portrait('puppy.jpg', 'Golden retriever')
status = check_status(request_id)
print(f"Status: {status['status']}, Progress: {status['progress']}%")
```

---

## Support & Troubleshooting

### Service Not Responding

```bash
# Check if service is running
curl http://localhost:8000/health

# View logs
docker-compose logs web-app
```

### Timeout Errors

- AI Service: May take up to 300 seconds for large images
- Printing Service: Typically < 5 seconds

### File Upload Issues

- Max file size: Not limited (Docker default: 1GB)
- Supported formats: JPEG, PNG, WebP
- Required: At least one of image or description

---

## Versioning

Current version: **1.0.0**

API is stable. Breaking changes will be communicated in advance.

---

## Rate Limiting (Future)

```
Tier        Requests/min    Use Case
Free        10              Demo/testing
Starter     100             Small business
Pro         1,000           Medium business
Enterprise  Unlimited       Large enterprise
```

---

## Changelog

### v1.0.0 (2024-01-15)
- Initial release
- File upload with AI generation
- Order tracking
- Service health checks

### v2.0.0 (Planned)
- User authentication & profiles
- Order history
- Real Stable Diffusion integration
- Payment processing
- Email notifications
- Web UI

---

End of API Documentation
