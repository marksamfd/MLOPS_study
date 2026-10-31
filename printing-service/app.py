"""
Printing Service
Pet Portrait Generator Platform - Printing & Shipping Management
"""

from flask import Flask, request, jsonify
import os
import json
from datetime import datetime, timedelta
import uuid
import logging
import traceback

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

ORDERS_DIR = "orders"
os.makedirs(ORDERS_DIR, exist_ok=True)

# In-memory order database (for demo purposes)
# In production, use PostgreSQL, MongoDB, etc.
orders = {}


@app.route("/health", methods=["GET"])
def health_check():
    """Health check endpoint"""
    logger.info("Health check request")
    return jsonify({
        "status": "healthy",
        "service": "printing-service",
        "timestamp": datetime.now().isoformat(),
        "total_orders": len(orders)
    }), 200


@app.route("/queue", methods=["POST"])
def queue_order():
    """Queue an order for printing and shipping"""
    try:
        data = request.get_json()
        request_id = data.get("request_id")
        image_path = data.get("image_path")
        timestamp = data.get("timestamp")

        if not request_id or not image_path:
            logger.warning(f"Missing request_id or image_path")
            return jsonify({
                "error": "Missing request_id or image_path"
            }), 400

        logger.info(f"Queueing order {request_id}")
        logger.info(f"Image: {image_path}")

        # Create order object
        order = {
            "request_id": request_id,
            "image_path": image_path,
            "status": "queued",
            "created_at": timestamp or datetime.now().isoformat(),
            "estimated_delivery": (datetime.now() + timedelta(days=7)).isoformat(),
            "canvas_size": "11x14 inches",
            "frame": "Black wood frame",
            "price": 49.99,
            "shipping_address": None,
        }

        # Store in memory
        orders[request_id] = order

        # Persist to file
        order_file = f"{ORDERS_DIR}/{request_id}_order.json"
        with open(order_file, "w") as f:
            json.dump(order, f, indent=2)

        logger.info(f"Order {request_id} queued successfully")
        logger.info(f"Order file saved: {order_file}")

        return jsonify({
            "message": "Order queued for printing and shipping",
            "order_id": request_id,
            "status": "queued",
            "estimated_delivery": order["estimated_delivery"],
            "canvas_size": order["canvas_size"],
            "price": order["price"]
        }), 200

    except Exception as e:
        logger.error(f"Error queueing order: {e}")
        logger.error(traceback.format_exc())
        return jsonify({
            "error": f"Failed to queue order: {str(e)}"
        }), 500


@app.route("/status/<request_id>", methods=["GET"])
def get_order_status(request_id):
    """Get the status of an order"""
    try:
        logger.info(f"Status check for order: {request_id}")

        # Try to load from file or memory
        order_file = f"{ORDERS_DIR}/{request_id}_order.json"
        
        if request_id in orders:
            order = orders[request_id]
            logger.info(f"Order found in memory: {request_id}")
        elif os.path.exists(order_file):
            with open(order_file, "r") as f:
                order = json.load(f)
            logger.info(f"Order loaded from file: {request_id}")
        else:
            logger.warning(f"Order not found: {request_id}")
            return jsonify({
                "error": f"Order {request_id} not found"
            }), 404

        # Simulate status progression based on elapsed time
        created_at = datetime.fromisoformat(order["created_at"])
        time_elapsed_hours = (datetime.now() - created_at).total_seconds() / 3600

        logger.info(f"Order {request_id}: {time_elapsed_hours:.1f} hours elapsed")

        # Status progression simulation
        if time_elapsed_hours < 1:
            order["status"] = "queued"
            order["status_message"] = "Order received and queued for printing"
            order["progress"] = 10
        elif time_elapsed_hours < 2:
            order["status"] = "printing"
            order["status_message"] = "Currently printing your portrait on canvas"
            order["progress"] = 40
        elif time_elapsed_hours < 4:
            order["status"] = "packaging"
            order["status_message"] = "Portrait is being framed and packaged"
            order["progress"] = 70
        elif time_elapsed_hours < 12:
            order["status"] = "shipped"
            order["status_message"] = "Order has been shipped! Tracking: TRACK123"
            order["progress"] = 100
            order["tracking_number"] = "TRACK123"
        else:
            order["status"] = "delivered"
            order["status_message"] = "Delivered to your address"
            order["progress"] = 100

        # Update in memory
        orders[request_id] = order

        logger.info(f"Order {request_id} status: {order['status']}")

        return jsonify(order), 200

    except Exception as e:
        logger.error(f"Error retrieving status: {e}")
        logger.error(traceback.format_exc())
        return jsonify({
            "error": f"Failed to retrieve status: {str(e)}"
        }), 500


@app.route("/orders", methods=["GET"])
def list_orders():
    """List all orders (for admin/dashboard)"""
    try:
        logger.info(f"Listing all orders (total: {len(orders)})")
        
        # Get status for all orders
        for order_id in list(orders.keys()):
            order_file = f"{ORDERS_DIR}/{order_id}_order.json"
            if os.path.exists(order_file):
                with open(order_file, "r") as f:
                    orders[order_id] = json.load(f)

        return jsonify({
            "total_orders": len(orders),
            "orders": list(orders.values())
        }), 200

    except Exception as e:
        logger.error(f"Error listing orders: {e}")
        return jsonify({"error": str(e)}), 500


@app.route("/", methods=["GET"])
def root():
    """Service information"""
    return jsonify({
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
            {"size": "16x20 inches", "price": 69.99},
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
            "orders": "/orders (GET)",
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
    logger.info("Starting Printing Service on port 5001")
    app.run(host="0.0.0.0", port=5001, debug=False)
