"""
Web Application Service
Pet Portrait Generator Platform - FastAPI Web Application
"""

from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
import httpx
import uuid
import os
from datetime import datetime
import logging

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Pet Portrait Platform - Web Application",
    description="Upload pet photos and scene descriptions to generate artistic portraits",
    version="1.0.0"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Service URLs from environment
AI_SERVICE_URL = os.getenv("AI_SERVICE_URL", "http://ai-service:5000")
PRINTING_SERVICE_URL = os.getenv("PRINTING_SERVICE_URL", "http://printing-service:5001")

# Create uploads directory
os.makedirs("uploads", exist_ok=True)


@app.get("/health")
async def health_check():
    """Health check endpoint for monitoring and orchestration"""
    return {
        "status": "healthy",
        "service": "web-app",
        "timestamp": datetime.now().isoformat()
    }


@app.post("/upload")
async def upload_image(file: UploadFile = File(...), description: str = None):
    """
    Upload a pet photo or scene description for portrait generation.
    
    - **file**: Image file (jpg, png, etc.)
    - **description**: Optional text description of the scene/pet
    
    Returns request_id for status tracking
    """
    if not file.filename:
        raise HTTPException(status_code=400, detail="No file provided")

    try:
        # Save uploaded file
        request_id = str(uuid.uuid4())
        filename = f"uploads/{request_id}_{file.filename}"
        
        logger.info(f"Saving upload: {filename}")
        with open(filename, "wb") as f:
            content = await file.read()
            f.write(content)
        
        logger.info(f"Calling AI service to generate portrait for {request_id}")
        
        # Call AI service to generate portrait
        async with httpx.AsyncClient(timeout=300.0) as client:
            ai_response = await client.post(
                f"{AI_SERVICE_URL}/generate",
                json={
                    "image_path": filename,
                    "description": description
                }
            )

        if ai_response.status_code != 200:
            logger.error(f"AI service error: {ai_response.status_code}")
            raise HTTPException(
                status_code=ai_response.status_code,
                detail=f"AI service error: {ai_response.text}"
            )

        ai_result = ai_response.json()
        generated_image = ai_result.get("image_path")
        
        logger.info(f"Portrait generated: {generated_image}")
        logger.info(f"Queuing order {request_id} to printing service")

        # Send to printing service
        async with httpx.AsyncClient(timeout=30.0) as client:
            print_response = await client.post(
                f"{PRINTING_SERVICE_URL}/queue",
                json={
                    "request_id": request_id,
                    "image_path": generated_image,
                    "timestamp": datetime.now().isoformat(),
                }
            )

        if print_response.status_code != 200:
            logger.error(f"Printing service error: {print_response.status_code}")
            raise HTTPException(
                status_code=500,
                detail="Printing service error"
            )

        logger.info(f"Order {request_id} successfully queued")

        return JSONResponse({
            "request_id": request_id,
            "message": "Portrait generated and queued for printing",
            "generated_image": generated_image,
            "filename": file.filename,
            "timestamp": datetime.now().isoformat()
        }, status_code=201)

    except httpx.RequestError as e:
        logger.error(f"Service communication error: {e}")
        raise HTTPException(
            status_code=503,
            detail=f"Service unavailable: {str(e)}"
        )
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Internal server error: {str(e)}"
        )


@app.get("/status/{request_id}")
async def get_status(request_id: str):
    """Get the current status of an order"""
    try:
        logger.info(f"Checking status for order: {request_id}")
        
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.get(
                f"{PRINTING_SERVICE_URL}/status/{request_id}"
            )

        if response.status_code != 200:
            raise HTTPException(
                status_code=404,
                detail=f"Order {request_id} not found"
            )

        return response.json()

    except httpx.RequestError:
        raise HTTPException(status_code=503, detail="Printing service unavailable")
    except Exception as e:
        logger.error(f"Error checking status: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")


@app.get("/orders")
async def list_orders():
    """List all uploaded files (for demo purposes)"""
    try:
        files = os.listdir("uploads") if os.path.exists("uploads") else []
        return {
            "total_uploads": len(files),
            "files": files[:10]  # Return first 10
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/")
async def root():
    """Service information and documentation"""
    return {
        "service": "Pet Portrait Generator - Web Application",
        "version": "1.0.0",
        "description": "Main API for uploading pet photos and managing portrait orders",
        "endpoints": {
            "documentation": "/docs",
            "health": "/health (GET)",
            "upload": "/upload (POST)",
            "status": "/status/{request_id} (GET)",
            "orders": "/orders (GET)",
        },
        "ai_service": AI_SERVICE_URL,
        "printing_service": PRINTING_SERVICE_URL,
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
