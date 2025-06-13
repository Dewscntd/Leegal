# ContractAnalyzer Kubernetes Quick Reference

## 🚀 Quick Start Commands

### Bootstrap Development Environment
```bash
# Create k3d cluster with everything installed
./scripts/k3d_bootstrap.sh

# Access ArgoCD UI
open https://localhost:8080
# Username: admin, Password: (shown in bootstrap output)
```

### Manual Deployment
```bash
# Install with Helm
cd deploy && make install

# Install with ArgoCD
kubectl apply -f deploy/argocd/app.yaml
```

## 📊 Monitoring & Status

### Check Application Status
```bash
# Overall status
cd deploy && make status

# ArgoCD applications
kubectl get applications -n argocd

# Service pods
kubectl get pods -n contract-analyzer

# Autoscaling status
kubectl get hpa -n contract-analyzer
kubectl get scaledobjects -n contract-analyzer
```

### View Logs
```bash
# All services
cd deploy && make logs

# Specific service
kubectl logs -f deployment/contract-analyzer-api-gateway -n contract-analyzer
```

### Port Forwarding
```bash
# API Gateway
kubectl port-forward svc/contract-analyzer-api-gateway 3000:3000 -n contract-analyzer

# ArgoCD (if not using bootstrap script)
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

## 🔧 Development Operations

### Update Application
```bash
# Upgrade with Helm
cd deploy && make upgrade

# Sync with ArgoCD
argocd app sync contract-analyzer
```

### Scale Services
```bash
# Manual scaling
kubectl scale deployment contract-analyzer-api-gateway --replicas=5 -n contract-analyzer

# Update HPA
kubectl patch hpa contract-analyzer-api-gateway -n contract-analyzer -p '{"spec":{"maxReplicas":15}}'
```

### Configuration Changes
```bash
# Edit values
vim deploy/charts/contract-analyzer/values.yaml

# Apply changes
cd deploy && make upgrade
```

## 🧪 Testing & Validation

### Validate Charts
```bash
# Validate all charts
./scripts/validate-helm-charts.sh

# Lint with Helm (requires Helm installed)
cd deploy && make lint

# Generate manifests
cd deploy && make template
```

### Test Deployment
```bash
# Run Helm tests
cd deploy && make test

# Check health endpoints
kubectl exec -it deployment/contract-analyzer-api-gateway -n contract-analyzer -- curl localhost:3000/healthz
```

## 🧹 Cleanup

### Remove Application
```bash
# Uninstall with Helm
cd deploy && make uninstall

# Delete ArgoCD application
kubectl delete application contract-analyzer -n argocd
```

### Remove k3d Cluster
```bash
# Complete cleanup
cd deploy && make clean

# Or manually
k3d cluster delete ca-dev
```

## 🔍 Troubleshooting

### Common Issues

**Pods not starting:**
```bash
# Check events
kubectl get events -n contract-analyzer --sort-by='.lastTimestamp'

# Check pod details
kubectl describe pod <pod-name> -n contract-analyzer
```

**Image pull errors:**
```bash
# Check image configuration
kubectl get deployment contract-analyzer-api-gateway -n contract-analyzer -o yaml | grep image

# Update image
kubectl set image deployment/contract-analyzer-api-gateway api-gateway=contract-analyzer/api-gateway:v1.0.0 -n contract-analyzer
```

**Database connection issues:**
```bash
# Check environment variables
kubectl exec deployment/contract-analyzer-api-gateway -n contract-analyzer -- env | grep DATABASE

# Test database connectivity
kubectl run -it --rm debug --image=postgres:16-alpine --restart=Never -- psql $DATABASE_URL
```

### Useful Debugging Commands
```bash
# Get all resources
kubectl get all -n contract-analyzer

# Check resource usage
kubectl top pods -n contract-analyzer

# View configuration
kubectl get configmap -n contract-analyzer
kubectl get secret -n contract-analyzer

# Check RBAC
kubectl auth can-i --list --as=system:serviceaccount:contract-analyzer:default
```

## 📚 Configuration Reference

### Environment Variables
- `NODE_ENV`: Application environment (development/staging/production)
- `PORT`: Service port (3000)
- `DATABASE_URL`: PostgreSQL connection string
- `REDIS_URL`: Redis connection string
- `RABBITMQ_URL`: RabbitMQ connection string
- `QDRANT_URL`: Qdrant vector database URL

### Resource Limits (Default)
```yaml
resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi
```

### Autoscaling Configuration
```yaml
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
  targetMemoryUtilizationPercentage: 80
```

## 🔗 Useful Links

- **ArgoCD UI**: https://localhost:8080
- **Grafana** (if using docker-compose): http://localhost:3005
- **Prometheus** (if using docker-compose): http://localhost:9090
- **RabbitMQ Management** (if using docker-compose): http://localhost:15672

## 📞 Support

For issues or questions:
1. Check the logs: `cd deploy && make logs`
2. Validate configuration: `./scripts/validate-helm-charts.sh`
3. Review the full documentation: `deploy/README.md`
4. Check Task 1.3 completion report: `TASK_1_3_COMPLETION.md`
