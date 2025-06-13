#!/bin/bash

# k3d Bootstrap Script for ContractAnalyzer
# Creates k3d cluster, installs Ingress-NGINX, ArgoCD 2.11, and deploys the application

set -e

# Configuration
CLUSTER_NAME="ca-dev"
ARGOCD_VERSION="v2.11.0"
NGINX_VERSION="v1.10.0"
KEDA_VERSION="v2.12.0"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if ! command -v k3d &> /dev/null; then
        log_error "k3d is not installed. Please install k3d first."
        exit 1
    fi
    
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed. Please install kubectl first."
        exit 1
    fi
    
    if ! command -v helm &> /dev/null; then
        log_error "helm is not installed. Please install helm first."
        exit 1
    fi
    
    log_success "All prerequisites are installed"
}

# Create k3d cluster
create_cluster() {
    log_info "Creating k3d cluster: ${CLUSTER_NAME}..."
    
    # Check if cluster already exists
    if k3d cluster list | grep -q "${CLUSTER_NAME}"; then
        log_warning "Cluster ${CLUSTER_NAME} already exists. Deleting it first..."
        k3d cluster delete "${CLUSTER_NAME}"
    fi
    
    # Create cluster with port mappings for ingress
    k3d cluster create "${CLUSTER_NAME}" \
        --port "80:80@loadbalancer" \
        --port "443:443@loadbalancer" \
        --port "8080:8080@loadbalancer" \
        --k3s-arg "--disable=traefik@server:0" \
        --agents 2 \
        --wait
    
    # Set kubectl context
    kubectl config use-context "k3d-${CLUSTER_NAME}"
    
    log_success "k3d cluster ${CLUSTER_NAME} created successfully"
}

# Install Ingress-NGINX
install_ingress_nginx() {
    log_info "Installing Ingress-NGINX ${NGINX_VERSION}..."
    
    # Add ingress-nginx helm repository
    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    helm repo update
    
    # Install ingress-nginx
    helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
        --namespace ingress-nginx \
        --create-namespace \
        --version "${NGINX_VERSION}" \
        --set controller.service.type=LoadBalancer \
        --set controller.service.loadBalancerIP="" \
        --set controller.watchIngressWithoutClass=true \
        --set controller.service.externalTrafficPolicy=Local \
        --wait
    
    log_success "Ingress-NGINX installed successfully"
}

# Install KEDA
install_keda() {
    log_info "Installing KEDA ${KEDA_VERSION}..."
    
    # Add KEDA helm repository
    helm repo add kedacore https://kedacore.github.io/charts
    helm repo update
    
    # Install KEDA
    helm upgrade --install keda kedacore/keda \
        --namespace keda-system \
        --create-namespace \
        --version "${KEDA_VERSION}" \
        --wait
    
    log_success "KEDA installed successfully"
}

# Install ArgoCD
install_argocd() {
    log_info "Installing ArgoCD ${ARGOCD_VERSION}..."
    
    # Create argocd namespace
    kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
    
    # Install ArgoCD
    kubectl apply -n argocd -f "https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml"
    
    # Wait for ArgoCD to be ready
    log_info "Waiting for ArgoCD to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
    
    # Get ArgoCD admin password
    ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
    
    log_success "ArgoCD installed successfully"
    log_info "ArgoCD admin password: ${ARGOCD_PASSWORD}"
    
    # Port forward ArgoCD server (in background)
    log_info "Setting up port forwarding for ArgoCD (localhost:8080)..."
    kubectl port-forward svc/argocd-server -n argocd 8080:443 > /dev/null 2>&1 &
    ARGOCD_PF_PID=$!
    
    echo "${ARGOCD_PF_PID}" > /tmp/argocd-port-forward.pid
    log_info "ArgoCD will be available at https://localhost:8080"
    log_info "Port forward PID saved to /tmp/argocd-port-forward.pid"
}

# Deploy ContractAnalyzer application
deploy_application() {
    log_info "Deploying ContractAnalyzer application..."
    
    # Create contract-analyzer namespace
    kubectl create namespace contract-analyzer --dry-run=client -o yaml | kubectl apply -f -
    
    # Apply ArgoCD application
    if [ -f "deploy/argocd/app.yaml" ]; then
        kubectl apply -f deploy/argocd/app.yaml
        log_success "ContractAnalyzer ArgoCD application created"
    else
        log_error "ArgoCD application file not found: deploy/argocd/app.yaml"
        log_warning "Please ensure you're running this script from the project root directory"
        return 1
    fi
    
    # Wait for application to sync
    log_info "Waiting for application to sync (this may take a few minutes)..."
    sleep 30
    
    log_success "ContractAnalyzer application deployed successfully"
}

# Display cluster information
display_info() {
    log_success "🎉 k3d cluster setup completed successfully!"
    echo
    log_info "Cluster Information:"
    echo "  • Cluster Name: ${CLUSTER_NAME}"
    echo "  • Kubectl Context: k3d-${CLUSTER_NAME}"
    echo "  • Ingress-NGINX: Installed"
    echo "  • KEDA: Installed"
    echo "  • ArgoCD: Installed"
    echo
    log_info "Access Information:"
    echo "  • ArgoCD UI: https://localhost:8080"
    echo "  • ArgoCD Username: admin"
    echo "  • ArgoCD Password: ${ARGOCD_PASSWORD}"
    echo
    log_info "Useful Commands:"
    echo "  • View cluster: k3d cluster list"
    echo "  • Delete cluster: k3d cluster delete ${CLUSTER_NAME}"
    echo "  • Stop port forward: kill \$(cat /tmp/argocd-port-forward.pid)"
    echo "  • View ArgoCD apps: kubectl get applications -n argocd"
    echo "  • View pods: kubectl get pods -n contract-analyzer"
    echo
}

# Cleanup function
cleanup() {
    if [ -f "/tmp/argocd-port-forward.pid" ]; then
        PID=$(cat /tmp/argocd-port-forward.pid)
        if kill -0 "$PID" 2>/dev/null; then
            kill "$PID"
            rm -f /tmp/argocd-port-forward.pid
        fi
    fi
}

# Trap cleanup on script exit
trap cleanup EXIT

# Main execution
main() {
    log_info "🚀 Starting k3d bootstrap for ContractAnalyzer..."
    
    check_prerequisites
    create_cluster
    install_ingress_nginx
    install_keda
    install_argocd
    deploy_application
    display_info
    
    log_success "Bootstrap completed! 🎉"
}

# Run main function
main "$@"
