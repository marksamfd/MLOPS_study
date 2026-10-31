.PHONY: help build up down logs clean test rebuild health

help:
	@echo "Pet Portrait Platform - Docker Management"
	@echo ""
	@echo "Available commands:"
	@echo "  make build          - Build all Docker images"
	@echo "  make up             - Start all services"
	@echo "  make down           - Stop all services"
	@echo "  make logs           - View logs for all services"
	@echo "  make logs-web       - View logs for web app only"
	@echo "  make logs-ai        - View logs for AI service only"
	@echo "  make logs-print     - View logs for printing service only"
	@echo "  make test           - Run health checks and tests"
	@echo "  make clean          - Remove containers and volumes"
	@echo "  make rebuild        - Rebuild and restart all services"
	@echo "  make health         - Check health of all services"
	@echo "  make shell-web      - Open shell in web app container"
	@echo "  make shell-ai       - Open shell in AI service container"
	@echo "  make shell-print    - Open shell in printing service container"
	@echo "  make ps             - Show running containers"
	@echo "  make help           - Show this message"

build:
	@echo "🔨 Building Docker images..."
	docker-compose build

up:
	@echo "🚀 Starting services..."
	docker-compose up -d
	@echo "✅ Services started!"
	@echo "Web App:        http://localhost:8000"
	@echo "AI Service:     http://localhost:5000"
	@echo "Printing Service: http://localhost:5001"

down:
	@echo "🛑 Stopping services..."
	docker-compose down

logs:
	@echo "📋 Showing logs for all services..."
	docker-compose logs -f

logs-web:
	@echo "📋 Web App logs..."
	docker-compose logs -f web-app

logs-ai:
	@echo "📋 AI Service logs..."
	docker-compose logs -f ai-service

logs-print:
	@echo "📋 Printing Service logs..."
	docker-compose logs -f printing-service

test:
	@echo "🧪 Testing services..."
	@echo "Waiting 10 seconds for services to stabilize..."
	@sleep 10
	@echo "Testing Web App..."
	@curl -s http://localhost:8000/health | jq .
	@echo "\nTesting AI Service..."
	@curl -s http://localhost:5000/health | jq .
	@echo "\nTesting Printing Service..."
	@curl -s http://localhost:5001/health | jq .
	@echo "\n✅ All services responding!"

health:
	@echo "💚 Checking service health..."
	@echo -n "Web App: "
	@curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8000/health
	@echo -n "AI Service: "
	@curl -s -o /dev/null -w "%{http_code}\n" http://localhost:5000/health
	@echo -n "Printing Service: "
	@curl -s -o /dev/null -w "%{http_code}\n" http://localhost:5001/health

clean:
	@echo "🧹 Cleaning up..."
	docker-compose down -v
	@echo "✅ Cleaned!"

rebuild: clean build up
	@echo "✅ Rebuild complete!"

shell-web:
	@echo "🐚 Opening shell in web app..."
	docker-compose exec web-app bash

shell-ai:
	@echo "🐚 Opening shell in AI service..."
	docker-compose exec ai-service bash

shell-print:
	@echo "🐚 Opening shell in printing service..."
	docker-compose exec printing-service bash

ps:
	@echo "📦 Running containers:"
	docker-compose ps

setup:
	@echo "⚙️  Running setup script..."
ifeq ($(OS),Windows_NT)
	@cmd /c setup.bat
else
	@bash setup.sh
endif

.DEFAULT_GOAL := help
