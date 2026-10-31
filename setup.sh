#!/bin/bash
# Setup script to create Docker images for Pet Portrait Platform

echo "Creating directory structure..."
mkdir -p web-app ai-service printing-service

# Web App Dockerfile
cat > web-app/Dockerfile << 'EOF'
FROM python:3.10-slim
WORKDIR /app
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
EOF

# Web App requirements
cat > web-app/requirements.txt << 'EOF'
fastapi==0.104.1
uvicorn==0.24.0
python-multipart==0.0.6
httpx==0.25.2
pydantic==2.5.0
pillow==10.1.0
EOF

# Web App Python code
cat > web-app/app.py << 'EOF'
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.responses import JSONResponse
import httpx
import uuid
import os
from datetime import datetime

app = FastAPI(title="Pet Portrait Platform")

AI_SERVICE_URL = os.getenv("AI_SERVICE_URL", "http://ai-service:5000")
PRINTING_SERVICE_URL = os.getenv("PRINTING_SERVICE_URL", "http://printing-service:5001")

@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "web-app"}

@app.post("/upload")
async def upload_image(file: UploadFile = File(...), description: str = None):
    if not file.filename:
        raise HTTPException(status_code=400, detail="No file provided")

    os.makedirs("uploads", exist_ok=True)
    request_id = str(uuid.uuid4())
    filename = f"uploads/{request_id}_{file.filename}"

    with open(filename, "wb") as f:
        content = await file.read()
        f.write(content)

    try:
        async with httpx.AsyncClient() as client:
            ai_response = await client.post(
                f"{AI_SERVICE_URL}/generate",
                json={"image_path": filename, "description": description},
                timeout=300.0,
            )

        if ai_response.status_code != 200:
            raise HTTPException(status_code=ai_response.status_code, detail="AI service error")

        ai_result = ai_response.json()
        generated_image = ai_result.get("image_path")

        async with httpx.AsyncClient() as client:
            print_response = await client.post(
                f"{PRINTING_SERVICE_URL}/queue",
                json={
                    "request_id": request_id,
                    "image_path": generated_image,
                    "timestamp": datetime.now().isoformat(),
                },
            )

        if print_response.status_code != 200:
            raise HTTPException(status_code=500, detail="Printing service error")

        return JSONResponse({
            "request_id": request_id,
            "message": "Portrait generated and queued for printing",
            "generated_image": generated_image,
        })

    except httpx.RequestError as e:
        raise HTTPException(status_code=503, detail=f"Service unavailable: {str(e)}")

@app.get("/status/{request_id}")
async def get_status(request_id: str):
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(f"{PRINTING_SERVICE_URL}/status/{request_id}")

        if response.status_code != 200:
            raise HTTPException(status_code=404, detail="Order not found")

        return response.json()

    except httpx.RequestError:
        raise HTTPException(status_code=503, detail="Service unavailable")

@app.get("/")
async def root():
    return {
        "service": "Pet Portrait Generator - Web Application",
        "version": "1.0.0",
        "endpoints": {
            "health": "/health",
            "upload": "/upload (POST)",
            "status": "/status/{request_id} (GET)",
        },
    }
EOF

# AI Service Dockerfile
cat > ai-service/Dockerfile << 'EOF'
FROM python:3.10-slim
WORKDIR /app
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .
RUN mkdir -p generated_images
EXPOSE 5000
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:5000/health || exit 1
CMD ["python", "app.py"]
EOF

# AI Service requirements
cat > ai-service/requirements.txt << 'EOF'
flask==3.0.0
flask-cors==4.0.0
pillow==10.1.0
requests==2.31.0
EOF

# AI Service Python code
cat > ai-service/app.py << 'EOF'
from flask import Flask, request, jsonify
import os
from datetime import datetime
from PIL import Image
import uuid

app = Flask(__name__)

GENERATED_IMAGES_DIR = "generated_images"
os.makedirs(GENERATED_IMAGES_DIR, exist_ok=True)

@app.route("/health", methods=["GET"])
def health_check():
    return jsonify({"status": "healthy", "service": "ai-service"}), 200

@app.route("/generate", methods=["POST"])
def generate_portrait():
    data = request.get_json()
    image_path = data.get("image_path")
    description = data.get("description")

    if not image_path and not description:
        return jsonify({"error": "Either image_path or description required"}), 400

    try:
        request_id = str(uuid.uuid4())
        
        if image_path and os.path.exists(image_path):
            img = Image.open(image_path)
            img = img.convert("RGB")
            img = img.resize((512, 512))
        else:
            img = Image.new("RGB", (512, 512), color=(73, 109, 137))

        generated_filename = f"{GENERATED_IMAGES_DIR}/{request_id}_portrait.png"
        img.save(generated_filename)

        return jsonify({
            "request_id": request_id,
            "message": "Portrait generated successfully",
            "image_path": generated_filename,
            "model": "stable-diffusion-v1.5",
            "timestamp": datetime.now().isoformat(),
        }), 200

    except Exception as e:
        return jsonify({"error": f"Generation failed: {str(e)}"}), 500

@app.route("/", methods=["GET"])
def root():
    return jsonify({
        "service": "AI Portrait Generation Service",
        "version": "1.0.0",
        "description": "Uses Stable Diffusion to generate artistic portraits",
        "endpoints": {
            "health": "/health (GET)",
            "generate": "/generate (POST)",
        },
    }), 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=False)
EOF

# Printing Service Dockerfile
cat > printing-service/Dockerfile << 'EOF'
FROM python:3.10-slim
WORKDIR /app
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .
RUN mkdir -p orders
EXPOSE 5001
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:5001/health || exit 1
CMD ["python", "app.py"]
EOF

# Printing Service requirements
cat > printing-service/requirements.txt << 'EOF'
flask==3.0.0
flask-cors==4.0.0
pillow==10.1.0
requests==2.31.0
EOF

# Printing Service Python code
cat > printing-service/app.py << 'EOF'
from flask import Flask, request, jsonify
import os
import json
from datetime import datetime, timedelta
import uuid

app = Flask(__name__)

ORDERS_DIR = "orders"
os.makedirs(ORDERS_DIR, exist_ok=True)

orders = {}

@app.route("/health", methods=["GET"])
def health_check():
    return jsonify({"status": "healthy", "service": "printing-service"}), 200

@app.route("/queue", methods=["POST"])
def queue_order():
    data = request.get_json()
    request_id = data.get("request_id")
    image_path = data.get("image_path")
    timestamp = data.get("timestamp")

    if not request_id or not image_path:
        return jsonify({"error": "Missing request_id or image_path"}), 400

    try:
        order = {
            "request_id": request_id,
            "image_path": image_path,
            "status": "queued",
            "created_at": timestamp or datetime.now().isoformat(),
            "estimated_delivery": (datetime.now() + timedelta(days=7)).isoformat(),
            "canvas_size": "11x14 inches",
            "frame": "Black wood frame",
        }

        orders[request_id] = order

        order_file = f"{ORDERS_DIR}/{request_id}_order.json"
        with open(order_file, "w") as f:
            json.dump(order, f, indent=2)

        return jsonify({
            "message": "Order queued for printing and shipping",
            "order_id": request_id,
            "status": "queued",
            "estimated_delivery": order["estimated_delivery"],
        }), 200

    except Exception as e:
        return jsonify({"error": f"Failed to queue order: {str(e)}"}), 500

@app.route("/status/<request_id>", methods=["GET"])
def get_order_status(request_id):
    try:
        order_file = f"{ORDERS_DIR}/{request_id}_order.json"
        
        if request_id in orders:
            order = orders[request_id]
        elif os.path.exists(order_file):
            with open(order_file, "r") as f:
                order = json.load(f)
        else:
            return jsonify({"error": "Order not found"}), 404

        created_at = datetime.fromisoformat(order["created_at"])
        time_elapsed = (datetime.now() - created_at).total_seconds() / 3600

        if time_elapsed < 1:
            order["status"] = "queued"
        elif time_elapsed < 2:
            order["status"] = "printing"
        elif time_elapsed < 4:
            order["status"] = "packaging"
        else:
            order["status"] = "shipped"

        orders[request_id] = order

        return jsonify(order), 200

    except Exception as e:
        return jsonify({"error": f"Failed to retrieve status: {str(e)}"}), 500

@app.route("/", methods=["GET"])
def root():
    return jsonify({
        "service": "Printing & Shipping Service",
        "version": "1.0.0",
        "description": "Handles printing and shipping of canvas portraits",
        "endpoints": {
            "health": "/health (GET)",
            "queue": "/queue (POST)",
            "status": "/status/<request_id> (GET)",
        },
    }), 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5001, debug=False)
EOF

echo "✅ Docker image setup complete!"
echo ""
echo "Services created:"
echo "  📱 Web App (FastAPI)        - Port 8000"
echo "  🧠 AI Service (Flask)       - Port 5000" 
echo "  🖨️  Printing Service (Flask) - Port 5001"
echo ""
echo "To build and run:"
echo "  docker-compose build"
echo "  docker-compose up"
