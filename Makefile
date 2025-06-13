# ContractAnalyzer Development Makefile
# POSIX-compliant shell commands for cross-platform compatibility

.PHONY: help dev-up dev-down dev-logs dev-status clean build-all generate-dockerfiles

# Default target
help: ## Show this help message
	@echo "ContractAnalyzer Development Commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""

# Development environment
dev-up: ## Start all services with docker-compose (build and run)
	@echo "🚀 Starting ContractAnalyzer development environment..."
	docker-compose up --build -d
	@echo "✅ Services started. Access:"
	@echo "   - API Gateway: http://localhost:3000"
	@echo "   - Auth Service: http://localhost:3001"
	@echo "   - Analysis Service: http://localhost:3002"
	@echo "   - Citation Service: http://localhost:3003"
	@echo "   - OCR Wrapper: http://localhost:3004"
	@echo "   - Grafana: http://localhost:3005 (admin/admin)"
	@echo "   - Prometheus: http://localhost:9090"
	@echo "   - Jaeger: http://localhost:16686"
	@echo "   - RabbitMQ Management: http://localhost:15672 (guest/guest)"

dev-down: ## Stop and remove all containers
	@echo "🛑 Stopping ContractAnalyzer development environment..."
	docker-compose down
	@echo "✅ All services stopped"

dev-logs: ## Show logs from all services
	docker-compose logs -f

dev-status: ## Show status of all services
	@echo "📊 Service Status:"
	docker-compose ps

# Build targets
build-all: ## Build all Docker images without starting services
	@echo "🔨 Building all Docker images..."
	docker-compose build
	@echo "✅ All images built successfully"

# Dockerfile generation
generate-dockerfiles: ## Generate Dockerfiles for all services from template
	@echo "📝 Generating Dockerfiles from template..."
	@for service in api-gateway auth analysis citation ocr-wrapper; do \
		echo "Generating Dockerfile for $$service..."; \
		sed "s/\$${SERVICE}/$$service/g" Dockerfile.base.tpl > contract-analyzer/apps/$$service/Dockerfile.generated; \
	done
	@echo "✅ Dockerfiles generated in contract-analyzer/apps/*/Dockerfile.generated"

# Cleanup targets
clean: ## Remove all containers, images, and volumes
	@echo "🧹 Cleaning up Docker resources..."
	docker-compose down -v --rmi all --remove-orphans
	@echo "✅ Cleanup completed"

clean-volumes: ## Remove all Docker volumes (WARNING: This will delete all data)
	@echo "⚠️  WARNING: This will delete all persistent data!"
	@read -p "Are you sure? (y/N): " confirm && [ "$$confirm" = "y" ] || exit 1
	docker-compose down -v
	docker volume prune -f
	@echo "✅ All volumes removed"

# Development utilities
dev-restart: dev-down dev-up ## Restart the development environment

dev-rebuild: ## Rebuild and restart all services
	@echo "🔄 Rebuilding and restarting services..."
	docker-compose down
	docker-compose build --no-cache
	docker-compose up -d
	@echo "✅ Services rebuilt and restarted"

# Health checks
health-check: ## Check health of all services
	@echo "🏥 Checking service health..."
	@for port in 3000 3001 3002 3003 3004; do \
		echo -n "Checking service on port $$port: "; \
		if curl -f -s http://localhost:$$port/healthz > /dev/null 2>&1; then \
			echo "✅ Healthy"; \
		else \
			echo "❌ Unhealthy"; \
		fi; \
	done

# Database utilities
db-reset: ## Reset the database (WARNING: This will delete all data)
	@echo "⚠️  WARNING: This will reset the database and delete all data!"
	@read -p "Are you sure? (y/N): " confirm && [ "$$confirm" = "y" ] || exit 1
	docker-compose stop postgres
	docker-compose rm -f postgres
	docker volume rm $$(docker-compose config --volumes | grep postgres) 2>/dev/null || true
	docker-compose up -d postgres
	@echo "✅ Database reset completed"

# Monitoring shortcuts
logs-api: ## Show API Gateway logs
	docker-compose logs -f api-gateway

logs-auth: ## Show Auth service logs
	docker-compose logs -f auth

logs-analysis: ## Show Analysis service logs
	docker-compose logs -f analysis

logs-citation: ## Show Citation service logs
	docker-compose logs -f citation

logs-ocr: ## Show OCR Wrapper logs
	docker-compose logs -f ocr-wrapper

logs-infra: ## Show infrastructure service logs
	docker-compose logs -f postgres redis qdrant rabbitmq

# Quick development commands
quick-start: dev-up health-check ## Start services and run health check

# Production-like testing
prod-test: ## Test with production-like settings
	@echo "🧪 Testing with production-like settings..."
	NODE_ENV=production docker-compose -f docker-compose.yml -f docker-compose.prod.yml up --build -d
	@echo "✅ Production test environment started"
