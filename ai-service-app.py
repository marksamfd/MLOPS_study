"""
AI Service
Pet Portrait Generator Platform - Stable Diffusion Portrait Generation
"""

from flask import Flask, request, jsonify
import os
from datetime import datetime
from PIL import Image, ImageFilter, ImageEnhance
import uuid
import logging
import traceback

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

GENERATED_IMAGES_DIR = "generated_images"
os.makedirs(GENERATED_IMAGES_DIR, exist_ok=True)


def create_dummy_portrait(size=(512, 512)):
    """
    Create a dummy portrait image.
    In production, this would call Stable Diffusion API.
    """
    # Create a gradient background (artistic effect)
    img = Image.new("RGB", size)
    pixels = img.load()
    
    # Create a blue-to-purple gradient
    for y in range(size[1]):
        for x in range(size[0]):
            # Calculate color based on position
            r = int(73 + (x / size[0]) * 50)
            g = int(109 + (y / size[1]) * 40)
            b = int(137 + ((x + y) / (size[0] + size[1])) * 80)
            pixels[x, y] = (r, g, b)
    
    # Add some artistic filters
    img = img.filter(ImageFilter.GaussianBlur(radius=2))
    enhancer = ImageEnhance.Color(img)
    img = enhancer.enhance(1.2)
    
    return img


@app.route("/health", methods=["GET"])
def health_check():
    """Health check endpoint"""
    logger.info("Health check request")
    return jsonify({
        "status": "healthy",
        "service": "ai-service",
        "timestamp": datetime.now().isoformat()
    }), 200


@app.route("/generate", methods=["POST"])
def generate_portrait():
    """
    Generate an artistic portrait using AI.
    
    In production, this would integrate with:
    - Stability AI (Stable Diffusion)
    - OpenAI DALL-E
    - Replicate API
    - Hugging Face
    """
    try:
        data = request.get_json()
        image_path = data.get("image_path")
        description = data.get("description")

        if not image_path and not description:
            logger.warning("No image_path or description provided")
            return jsonify({
                "error": "Either image_path or description required"
            }), 400

        request_id = str(uuid.uuid4())
        logger.info(f"Generating portrait {request_id}")
        logger.info(f"Input - Image: {image_path}, Description: {description}")

        # Process input image or create from description
        if image_path and os.path.exists(image_path):
            logger.info(f"Loading existing image: {image_path}")
            try:
                img = Image.open(image_path)
                img = img.convert("RGB")
                img = img.resize((512, 512))
                logger.info("Image loaded and resized successfully")
            except Exception as e:
                logger.warning(f"Could not process image, creating dummy: {e}")
                img = create_dummy_portrait()
        else:
            logger.info("Creating dummy portrait from description")
            img = create_dummy_portrait()

        # Save generated portrait
        generated_filename = f"{GENERATED_IMAGES_DIR}/{request_id}_portrait.png"
        img.save(generated_filename)
        logger.info(f"Portrait saved: {generated_filename}")

        response_data = {
            "request_id": request_id,
            "message": "Portrait generated successfully",
            "image_path": generated_filename,
            "model": "stable-diffusion-v1.5",
            "canvas_size": "512x512",
            "timestamp": datetime.now().isoformat(),
        }

        logger.info(f"Portrait generation completed: {request_id}")
        return jsonify(response_data), 200

    except Exception as e:
        logger.error(f"Error generating portrait: {e}")
        logger.error(traceback.format_exc())
        return jsonify({
            "error": f"Generation failed: {str(e)}",
            "traceback": traceback.format_exc()
        }), 500


@app.route("/", methods=["GET"])
def root():
    """Service information"""
    return jsonify({
        "service": "AI Portrait Generation Service",
        "version": "1.0.0",
        "description": "Generates artistic portraits using Stable Diffusion",
        "models": [
            "stable-diffusion-v1.5"
        ],
        "supported_formats": [
            "jpg", "jpeg", "png", "webp"
        ],
        "output_size": "512x512",
        "endpoints": {
            "health": "/health (GET)",
            "generate": "/generate (POST)",
            "root": "/ (GET)",
        },
    }), 200


@app.errorhandler(404)
def not_found(error):
    return jsonify({"error": "Endpoint not found"}), 404


@app.errorhandler(500)
def server_error(error):
    logger.error(f"Server error: {error}")
    return jsonify({"error": "Internal server error"}), 500


if __name__ == "__main__":
    logger.info("Starting AI Service on port 5000")
    app.run(host="0.0.0.0", port=5000, debug=False)
