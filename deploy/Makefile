# ContractAnalyzer Kubernetes Deployment Makefile

.PHONY: help bootstrap clean install upgrade uninstall lint test template deps

# Default target
help: ## Show this help message
	@echo "ContractAnalyzer Kubernetes Deployment"
	@echo "======================================"
	@echo ""
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Variables
CHART_DIR := charts/contract-analyzer
NAMESPACE := contract-analyzer
RELEASE_NAME := contract-analyzer
VALUES_FILE := $(CHART_DIR)/values.yaml

# Bootstrap development environment
bootstrap: ## Create k3d cluster and deploy everything
	@echo "🚀 Bootstrapping development environment..."
	../scripts/k3d_bootstrap.sh

# Clean up development environment
clean: ## Delete k3d cluster and cleanup
	@echo "🧹 Cleaning up development environment..."
	k3d cluster delete ca-dev || true
	@if [ -f "/tmp/argocd-port-forward.pid" ]; then \
		kill $$(cat /tmp/argocd-port-forward.pid) 2>/dev/null || true; \
		rm -f /tmp/argocd-port-forward.pid; \
	fi

# Helm operations
deps: ## Update Helm chart dependencies
	@echo "📦 Updating Helm dependencies..."
	cd $(CHART_DIR) && helm dependency update

lint: ## Lint Helm charts
	@echo "🔍 Linting Helm charts..."
	helm lint $(CHART_DIR)
	@for chart in $(CHART_DIR)/charts/*; do \
		if [ -d "$$chart" ]; then \
			echo "Linting $$chart..."; \
			helm lint "$$chart"; \
		fi \
	done

template: ## Generate Kubernetes manifests from Helm charts
	@echo "📄 Generating Kubernetes manifests..."
	helm template $(RELEASE_NAME) $(CHART_DIR) \
		--namespace $(NAMESPACE) \
		--values $(VALUES_FILE) \
		--output-dir ./manifests
	@echo "✅ Manifests generated in ./manifests/"

test: ## Run Helm chart tests
	@echo "🧪 Running Helm chart tests..."
	helm test $(RELEASE_NAME) --namespace $(NAMESPACE)

# Deployment operations
install: deps ## Install the application with Helm
	@echo "📦 Installing ContractAnalyzer..."
	kubectl create namespace $(NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -
	helm install $(RELEASE_NAME) $(CHART_DIR) \
		--namespace $(NAMESPACE) \
		--values $(VALUES_FILE) \
		--wait

upgrade: deps ## Upgrade the application with Helm
	@echo "⬆️  Upgrading ContractAnalyzer..."
	helm upgrade $(RELEASE_NAME) $(CHART_DIR) \
		--namespace $(NAMESPACE) \
		--values $(VALUES_FILE) \
		--wait

uninstall: ## Uninstall the application
	@echo "🗑️  Uninstalling ContractAnalyzer..."
	helm uninstall $(RELEASE_NAME) --namespace $(NAMESPACE)
	kubectl delete namespace $(NAMESPACE) --ignore-not-found=true

# ArgoCD operations
argocd-install: ## Install ArgoCD application
	@echo "🔄 Installing ArgoCD application..."
	kubectl apply -f argocd/app.yaml

argocd-sync: ## Sync ArgoCD application
	@echo "🔄 Syncing ArgoCD application..."
	argocd app sync contract-analyzer

argocd-status: ## Show ArgoCD application status
	@echo "📊 ArgoCD application status:"
	kubectl get applications -n argocd
	argocd app get contract-analyzer

# Development helpers
dev-setup: ## Setup development environment (without k3d)
	@echo "🛠️  Setting up development environment..."
	@echo "Installing required tools..."
	@command -v helm >/dev/null 2>&1 || { echo "Please install Helm"; exit 1; }
	@command -v kubectl >/dev/null 2>&1 || { echo "Please install kubectl"; exit 1; }
	@command -v k3d >/dev/null 2>&1 || { echo "Please install k3d"; exit 1; }
	@echo "✅ Development environment ready"

status: ## Show deployment status
	@echo "📊 Deployment Status:"
	@echo "===================="
	@echo ""
	@echo "Namespaces:"
	kubectl get namespaces | grep -E "(contract-analyzer|argocd)" || echo "No relevant namespaces found"
	@echo ""
	@echo "Pods in contract-analyzer namespace:"
	kubectl get pods -n $(NAMESPACE) 2>/dev/null || echo "Namespace not found"
	@echo ""
	@echo "Services in contract-analyzer namespace:"
	kubectl get services -n $(NAMESPACE) 2>/dev/null || echo "Namespace not found"
	@echo ""
	@echo "HPA status:"
	kubectl get hpa -n $(NAMESPACE) 2>/dev/null || echo "No HPA found"
	@echo ""
	@echo "KEDA ScaledObjects:"
	kubectl get scaledobjects -n $(NAMESPACE) 2>/dev/null || echo "No ScaledObjects found"

logs: ## Show logs for all services
	@echo "📋 Service Logs:"
	@echo "==============="
	@for service in api-gateway auth analysis citation ocr-wrapper; do \
		echo ""; \
		echo "=== $$service logs ==="; \
		kubectl logs -l app.kubernetes.io/name=$$service -n $(NAMESPACE) --tail=10 2>/dev/null || echo "No logs found for $$service"; \
	done

port-forward: ## Port forward to api-gateway service
	@echo "🔌 Port forwarding to api-gateway (localhost:3000)..."
	kubectl port-forward svc/contract-analyzer-api-gateway 3000:3000 -n $(NAMESPACE)

# Image operations
build-images: ## Build all Docker images
	@echo "🏗️  Building Docker images..."
	cd .. && make build-all

push-images: ## Push all Docker images
	@echo "📤 Pushing Docker images..."
	cd .. && make push-all

# Validation
validate: lint ## Validate Helm charts and manifests
	@echo "✅ Validating deployment configuration..."
	@echo "Checking chart structure..."
	@test -f $(CHART_DIR)/Chart.yaml || { echo "Chart.yaml not found"; exit 1; }
	@test -f $(CHART_DIR)/values.yaml || { echo "values.yaml not found"; exit 1; }
	@echo "Checking sub-charts..."
	@for service in api-gateway auth analysis citation ocr-wrapper; do \
		test -d $(CHART_DIR)/charts/$$service || { echo "Sub-chart $$service not found"; exit 1; }; \
	done
	@echo "✅ All validations passed"

# Monitoring
monitor: ## Open monitoring dashboards
	@echo "📊 Opening monitoring dashboards..."
	@echo "ArgoCD: https://localhost:8080"
	@echo "Grafana: http://localhost:3005 (if running via docker-compose)"
	@echo "Prometheus: http://localhost:9090 (if running via docker-compose)"

# Documentation
docs: ## Generate documentation
	@echo "📚 Generating documentation..."
	helm-docs $(CHART_DIR)
	@echo "✅ Documentation generated"
