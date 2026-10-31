#!/bin/bash

# Test script for Pet Portrait Platform

echo "🧪 Testing Pet Portrait Platform..."
echo ""

# Wait for services to be ready
echo "⏳ Waiting for services to start (30 seconds)..."
sleep 30

# Test Web App
echo "📱 Testing Web App..."
WEB_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health)
if [ "$WEB_HEALTH" = "200" ]; then
    echo "✅ Web App is healthy"
else
    echo "❌ Web App health check failed (HTTP $WEB_HEALTH)"
fi

echo ""
echo "WEB APP INFO:"
curl -s http://localhost:8000/ | jq .

# Test AI Service
echo ""
echo "🧠 Testing AI Service..."
AI_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/health)
if [ "$AI_HEALTH" = "200" ]; then
    echo "✅ AI Service is healthy"
else
    echo "❌ AI Service health check failed (HTTP $AI_HEALTH)"
fi

echo ""
echo "AI SERVICE INFO:"
curl -s http://localhost:5000/ | jq .

# Test Printing Service
echo ""
echo "🖨️  Testing Printing Service..."
PRINT_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5001/health)
if [ "$PRINT_HEALTH" = "200" ]; then
    echo "✅ Printing Service is healthy"
else
    echo "❌ Printing Service health check failed (HTTP $PRINT_HEALTH)"
fi

echo ""
echo "PRINTING SERVICE INFO:"
curl -s http://localhost:5001/ | jq .

echo ""
echo "✅ All services tested!"
echo ""
echo "Next steps:"
echo "1. Test file upload: curl -X POST -F 'file=@test.jpg' http://localhost:8000/upload"
echo "2. Check status: curl http://localhost:8000/status/REQUEST_ID"
echo "3. View logs: docker-compose logs -f"
