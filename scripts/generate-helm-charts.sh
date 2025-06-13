#!/bin/bash

# Generate Helm sub-charts for ContractAnalyzer services
# This script creates the remaining service charts based on the api-gateway template

set -e

SERVICES=("auth" "analysis" "citation" "ocr-wrapper")
BASE_DIR="deploy/charts/contract-analyzer/charts"
TEMPLATE_DIR="${BASE_DIR}/api-gateway"

echo "🚀 Generating Helm sub-charts for ContractAnalyzer services..."

for service in "${SERVICES[@]}"; do
    echo "📦 Creating chart for ${service}..."
    
    SERVICE_DIR="${BASE_DIR}/${service}"
    mkdir -p "${SERVICE_DIR}/templates"
    
    # Generate Chart.yaml
    cat > "${SERVICE_DIR}/Chart.yaml" << EOF
apiVersion: v2
name: ${service}
description: ContractAnalyzer ${service} service Helm chart
type: application
version: 0.1.0
appVersion: "0.1.0"
keywords:
  - ${service}
  - microservice
  - contract-analyzer
home: https://github.com/your-org/contract-analyzer
sources:
  - https://github.com/your-org/contract-analyzer
maintainers:
  - name: ContractAnalyzer Team
    email: team@contract-analyzer.com
EOF

    # Generate values.yaml
    cat > "${SERVICE_DIR}/values.yaml" << EOF
# Default values for ${service} service
replicaCount: 2

image:
  repository: contract-analyzer/${service}
  pullPolicy: IfNotPresent
  tag: "latest"

imagePullSecrets: []
nameOverride: ""
fullnameOverride: ""

serviceAccount:
  create: true
  annotations: {}
  name: ""

podAnnotations: {}

podSecurityContext:
  fsGroup: 2000

securityContext:
  capabilities:
    drop:
    - ALL
  readOnlyRootFilesystem: true
  runAsNonRoot: true
  runAsUser: 1000

service:
  type: ClusterIP
  port: 3000
  targetPort: 3000

ingress:
  enabled: false
  className: ""
  annotations: {}
  hosts:
    - host: ${service}.local
      paths:
        - path: /
          pathType: Prefix
  tls: []

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
  targetMemoryUtilizationPercentage: 80

nodeSelector: {}

tolerations: []

affinity: {}

# Environment variables
env:
  NODE_ENV: development
  PORT: "3000"

# ConfigMap data
config: {}

# Secret data (base64 encoded)
secrets: {}

# Health check configuration
healthCheck:
  enabled: true
  path: /healthz
  initialDelaySeconds: 30
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3
  successThreshold: 1

# Readiness probe configuration
readinessProbe:
  enabled: true
  path: /healthz
  initialDelaySeconds: 5
  periodSeconds: 5
  timeoutSeconds: 3
  failureThreshold: 3
  successThreshold: 1
EOF

    # Copy and modify template files
    for template in deployment.yaml service.yaml hpa.yaml serviceaccount.yaml configmap.yaml secret.yaml; do
        sed "s/api-gateway/${service}/g" "${TEMPLATE_DIR}/templates/${template}" > "${SERVICE_DIR}/templates/${template}"
    done
    
    # Generate _helpers.tpl
    sed "s/api-gateway/${service}/g" "${TEMPLATE_DIR}/templates/_helpers.tpl" > "${SERVICE_DIR}/templates/_helpers.tpl"
    
    echo "✅ Chart for ${service} created successfully"
done

echo "🎉 All Helm sub-charts generated successfully!"
echo "📁 Charts location: ${BASE_DIR}"
