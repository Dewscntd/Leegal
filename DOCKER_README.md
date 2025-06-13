# ContractAnalyzer Docker Setup

This document describes the Docker infrastructure setup for the ContractAnalyzer project, implementing Task 1.2 of the Week 0-1 infrastructure skeleton.

## Architecture Overview

The ContractAnalyzer uses a microservices architecture with the following components:

### Application Services
- **api-gateway** (Port 3000) - Main API Gateway using Apollo Federation
- **auth** (Port 3001) - Authentication and authorization service
- **analysis** (Port 3002) - Contract analysis and ML pipeline service
- **citation** (Port 3003) - Legal citation and reference service
- **ocr-wrapper** (Port 3004) - OCR processing wrapper service

### Infrastructure Services
- **PostgreSQL 16** (Port 5432) - Primary database with TimescaleDB extensions
- **Redis** (Port 6379) - Caching and session storage
- **Qdrant 1.8** (Port 6333/6334) - Vector database for ML embeddings
- **RabbitMQ 3.13** (Port 5672/15672) - Message queue with management UI
- **Jaeger** (Port 16686) - Distributed tracing
- **Prometheus** (Port 9090) - Metrics collection
- **Grafana** (Port 3005) - Monitoring dashboards

## Quick Start

### Prerequisites
- Docker v24+
- Node.js 20+
- npm (package-lock.json based project)

### Development Environment

```bash
# Start all services
make dev-up

# Check service health
make health-check

# View logs
make dev-logs

# Stop all services
make dev-down
```

### Available Make Commands

```bash
make help              # Show all available commands
make dev-up            # Start development environment
make dev-down          # Stop all services
make dev-logs          # Show logs from all services
make dev-status        # Show service status
make build-all         # Build all Docker images
make clean             # Remove containers, images, and volumes
make health-check      # Check health of all services
make db-reset          # Reset database (WARNING: deletes data)
```

## Docker Configuration

### Multi-Stage Dockerfile Template

The `Dockerfile.base.tpl` provides a reusable template for all microservices:

**Stage 1 (Builder):**
- Base: `node:20-alpine`
- Install dependencies: `npm ci`
- Build service: `nx run $SERVICE:build`

**Stage 2 (Production):**
- Base: `node:20-slim` (distroless style)
- Copy built application and production dependencies
- Run as non-root user for security
- Health check on `/healthz` endpoint

### Service-Specific Dockerfiles

Each service has its own Dockerfile generated from the template:
- `contract-analyzer/apps/Dockerfile` (api-gateway)
- `contract-analyzer/apps/auth/Dockerfile`
- `contract-analyzer/apps/analysis/Dockerfile`
- `contract-analyzer/apps/citation/Dockerfile`
- `contract-analyzer/apps/ocr-wrapper/Dockerfile`

### Nx Integration

The project includes an Nx target for Dockerfile generation:

```bash
# Generate Dockerfiles from template
npx nx run <service>:generate-dockerfile --service=<service-name>

# Or use the Makefile
make generate-dockerfiles
```

## Service URLs

After running `make dev-up`, services are available at:

- **API Gateway**: http://localhost:3000
- **Auth Service**: http://localhost:3001
- **Analysis Service**: http://localhost:3002
- **Citation Service**: http://localhost:3003
- **OCR Wrapper**: http://localhost:3004
- **Grafana Dashboard**: http://localhost:3005 (admin/admin)
- **Prometheus**: http://localhost:9090
- **Jaeger UI**: http://localhost:16686
- **RabbitMQ Management**: http://localhost:15672 (guest/guest)

## Health Checks

All application services implement health checks on the `/healthz` endpoint (port 3000 internally). The health check configuration:

- **Interval**: 30 seconds
- **Timeout**: 10 seconds
- **Retries**: 3
- **Start Period**: 40 seconds

## Environment Variables

### Common Variables
- `NODE_ENV`: Environment (development/production)
- `PORT`: Service port (default: 3000)
- `DATABASE_URL`: PostgreSQL connection string
- `REDIS_URL`: Redis connection string
- `RABBITMQ_URL`: RabbitMQ connection string

### Service-Specific Variables
- **Auth Service**: `JWT_SECRET`
- **Analysis Service**: `QDRANT_URL`
- **All Services**: Service-specific database schemas

## Data Persistence

The following volumes are created for data persistence:
- `postgres_data`: PostgreSQL database files
- `redis_data`: Redis persistence
- `qdrant_data`: Qdrant vector database
- `rabbitmq_data`: RabbitMQ data
- `prometheus_data`: Prometheus metrics
- `grafana_data`: Grafana dashboards and settings

## Monitoring and Observability

### Prometheus Configuration
- Scrapes metrics from all microservices every 30 seconds
- Infrastructure services monitored every 60 seconds
- Configuration: `config/prometheus.yml`

### Grafana Setup
- Pre-configured Prometheus datasource
- Dashboard provisioning ready
- Configuration: `config/grafana/provisioning/`

### Jaeger Tracing
- All-in-one deployment for development
- OTLP collector enabled
- Ready for distributed tracing implementation

## Development Workflow

1. **Start Environment**: `make dev-up`
2. **Check Health**: `make health-check`
3. **View Logs**: `make dev-logs` or service-specific logs
4. **Make Changes**: Edit code, services auto-rebuild on restart
5. **Restart Services**: `make dev-restart`
6. **Clean Up**: `make dev-down`

## Troubleshooting

### Common Issues

1. **Port Conflicts**: Ensure ports 3000-3005, 5432, 6379, 6333-6334, 5672, 15672, 9090, 16686 are available
2. **Build Failures**: Check Docker logs with `docker-compose logs <service>`
3. **Health Check Failures**: Verify services implement `/healthz` endpoint
4. **Database Connection**: Ensure PostgreSQL is fully started before application services

### Debugging Commands

```bash
# Check service status
make dev-status

# View specific service logs
make logs-api        # API Gateway logs
make logs-auth       # Auth service logs
make logs-infra      # Infrastructure logs

# Rebuild specific service
docker-compose build <service-name>

# Access service shell
docker-compose exec <service-name> sh
```

## Security Considerations

- All application containers run as non-root users
- Production dependencies only in final image
- Health checks prevent unhealthy containers from receiving traffic
- Network isolation through Docker networks
- Secrets should be managed through environment variables or Docker secrets

## Next Steps

This infrastructure setup provides the foundation for:
1. Implementing health check endpoints in each service
2. Adding metrics collection for Prometheus
3. Implementing distributed tracing with Jaeger
4. Setting up CI/CD pipelines
5. Production deployment with Kubernetes
