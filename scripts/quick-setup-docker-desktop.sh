#!/bin/bash
# Quick Setup for Docker Desktop
# Doc-Type: Automation Script · Version 1.0 · Updated 2025-11-10

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

main() {
    log_info "Setting up Kubernetes cluster on Docker Desktop..."

    log_info "Creating namespaces..."
    kubectl apply -f k8s/namespaces/namespaces.yaml

    log_info "Deploying resource quotas and limits..."
    kubectl apply -f k8s/core/resource-quotas.yaml

    log_info "Installing ArgoCD for GitOps..."
    kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
    kubectl apply -f config/gitops/argocd/install.yaml

    log_info "Waiting for ArgoCD to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd || true

    log_info "\n========================================="
    log_info "Docker Desktop Setup Complete!"
    log_info "========================================="
    echo ""
    log_info "ArgoCD Admin Password:"
    kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d || log_warn "ArgoCD not ready yet"
    echo ""
    echo ""
    log_info "Port Forward Services:"
    echo "  kubectl port-forward -n argocd svc/argocd-server 8080:443"
    echo ""
    log_info "Access ArgoCD:"
    echo "  https://localhost:8080"
    echo "  Username: admin"
    echo ""
    log_warn "Optional: Deploy monitoring stack with deploy-full-stack.sh"
}

main "$@"
