# ContractAnalyzer Kubernetes Deployment

This directory contains Helm charts and ArgoCD configuration for deploying the ContractAnalyzer microservices to Kubernetes.

## Architecture Overview

The ContractAnalyzer uses a microservices architecture with the following services:

- **api-gateway** (Port 3000) - GraphQL API Gateway with Apollo Federation
- **auth** (Port 3001) - Authentication and authorization service  
- **analysis** (Port 3002) - Contract analysis and ML pipeline service
- **citation** (Port 3003) - Legal citation and reference service
- **ocr-wrapper** (Port 3004) - OCR processing wrapper service

## Directory Structure

```
deploy/
├── charts/
│   └── contract-analyzer/          # Umbrella Helm chart
│       ├── Chart.yaml              # Chart metadata
│       ├── values.yaml             # Global configuration values
│       └── charts/                 # Sub-charts for each service
│           ├── api-gateway/
│           ├── auth/
│           ├── analysis/
│           ├── citation/
│           └── ocr-wrapper/
└── argocd/
    └── app.yaml                    # ArgoCD Application CR
```

## Quick Start with k3d

### Prerequisites

- [k3d](https://k3d.io/) v5.0+
- [kubectl](https://kubernetes.io/docs/tasks/tools/) v1.28+
- [helm](https://helm.sh/) v3.12+
- Docker v24+

### Bootstrap Development Environment

Run the bootstrap script to create a complete development environment:

```bash
./scripts/k3d_bootstrap.sh
```

This script will:
1. Create a k3d cluster named `ca-dev`
2. Install Ingress-NGINX controller
3. Install KEDA for autoscaling
4. Install ArgoCD v2.11
5. Deploy the ContractAnalyzer application

### Access Services

After bootstrap completion:

- **ArgoCD UI**: https://localhost:8080
  - Username: `admin`
  - Password: (displayed in script output)

- **Application Status**: 
  ```bash
  kubectl get applications -n argocd
  kubectl get pods -n contract-analyzer
  ```

## Manual Deployment

### 1. Install Helm Chart Dependencies

```bash
cd deploy/charts/contract-analyzer
helm dependency update
```

### 2. Deploy with Helm

```bash
# Create namespace
kubectl create namespace contract-analyzer

# Install/upgrade the application
helm upgrade --install contract-analyzer . \
  --namespace contract-analyzer \
  --values values.yaml
```

### 3. Deploy with ArgoCD

```bash
# Apply ArgoCD application
kubectl apply -f deploy/argocd/app.yaml

# Sync the application
argocd app sync contract-analyzer
```

## Configuration

### Global Values

Key configuration options in `values.yaml`:

```yaml
global:
  imageRegistry: ""                 # Container registry
  environment: development          # Environment (development/staging/production)
  
  # Database configuration
  database:
    host: postgres
    port: 5432
    name: contract_analyzer
    username: postgres
  
  # Message queue configuration  
  rabbitmq:
    host: rabbitmq
    port: 5672
    username: guest
```

### Service-Specific Configuration

Each service can be configured individually:

```yaml
api-gateway:
  enabled: true
  replicaCount: 2
  image:
    repository: contract-analyzer/api-gateway
    tag: "latest"
    pullPolicy: IfNotPresent
  
  resources:
    limits:
      cpu: 500m
      memory: 512Mi
    requests:
      cpu: 250m
      memory: 256Mi
  
  autoscaling:
    enabled: true
    minReplicas: 2
    maxReplicas: 10
    targetCPUUtilizationPercentage: 70
```

### KEDA Autoscaling

The `analysis` and `ocr-wrapper` services include KEDA-based autoscaling using RabbitMQ queue length:

```yaml
analysis:
  autoscaling:
    keda:
      enabled: true
      triggers:
        - type: rabbitmq
          metadata:
            queueName: analysis-queue
            host: amqp://guest:guest@rabbitmq:5672
            queueLength: "10"
```

## Environment Variables

Each service receives the following environment variables:

- `NODE_ENV`: Application environment (development/staging/production)
- `PORT`: Service port (3000)
- `DATABASE_URL`: PostgreSQL connection string
- `REDIS_URL`: Redis connection string  
- `RABBITMQ_URL`: RabbitMQ connection string
- `QDRANT_URL`: Qdrant vector database URL

## Health Checks

All services include:

- **Liveness Probe**: `/healthz` endpoint
- **Readiness Probe**: `/healthz` endpoint
- **Startup Probe**: 30s initial delay

## Security

- Services run as non-root user (UID 1000)
- Read-only root filesystem
- Security capabilities dropped
- Service accounts with minimal permissions

## Monitoring & Observability

The deployment includes:

- Prometheus metrics scraping annotations
- Structured logging with correlation IDs
- Distributed tracing with Jaeger
- Health check endpoints

## Troubleshooting

### Common Issues

1. **Pods not starting**: Check resource limits and node capacity
2. **Image pull errors**: Verify image registry and pull secrets
3. **Database connection**: Ensure PostgreSQL is running and accessible
4. **Queue scaling**: Verify RabbitMQ is running and KEDA is installed

### Useful Commands

```bash
# View application status
kubectl get applications -n argocd

# Check pod status
kubectl get pods -n contract-analyzer

# View service logs
kubectl logs -f deployment/api-gateway -n contract-analyzer

# Port forward to service
kubectl port-forward svc/api-gateway 3000:3000 -n contract-analyzer

# Scale service manually
kubectl scale deployment api-gateway --replicas=3 -n contract-analyzer

# View HPA status
kubectl get hpa -n contract-analyzer

# View KEDA scaled objects
kubectl get scaledobjects -n contract-analyzer
```

### Cleanup

```bash
# Delete k3d cluster
k3d cluster delete ca-dev

# Or delete just the application
helm uninstall contract-analyzer -n contract-analyzer
kubectl delete namespace contract-analyzer
```

## Development

### Adding New Services

1. Create new sub-chart in `charts/contract-analyzer/charts/`
2. Add dependency to umbrella chart `Chart.yaml`
3. Add service configuration to `values.yaml`
4. Update ArgoCD application if needed

### Updating Images

Update image tags in `values.yaml` or override via Helm:

```bash
helm upgrade contract-analyzer . \
  --set api-gateway.image.tag=v1.2.3 \
  --namespace contract-analyzer
```
