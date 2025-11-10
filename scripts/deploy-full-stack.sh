#!/bin/bash
# Full Stack Deployment Script
# Doc-Type: Automation Script · Version 1.0 · Updated 2025-11-10

set -euo pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    log_info "Checking prerequisites..."

    command -v kubectl >/dev/null 2>&1 || { log_error "kubectl is required but not installed"; exit 1; }
    command -v helm >/dev/null 2>&1 || { log_error "helm is required but not installed"; exit 1; }

    kubectl cluster-info >/dev/null 2>&1 || { log_error "Cannot connect to Kubernetes cluster"; exit 1; }

    log_info "Prerequisites check passed"
}

deploy_namespaces() {
    log_info "Creating namespaces..."
    kubectl apply -f k8s/namespaces/namespaces.yaml
}

deploy_core_resources() {
    log_info "Deploying core resources..."
    kubectl apply -f k8s/core/resource-quotas.yaml
    kubectl apply -f k8s/storage/storage-classes.yaml
    kubectl apply -f k8s/security/pod-security-standards.yaml
}

deploy_networking() {
    log_info "Deploying networking components..."
    kubectl apply -f k8s/networking/ingress-nginx.yaml
}

deploy_velero() {
    log_info "Deploying Velero backup system..."

    if ! kubectl get namespace velero >/dev/null 2>&1; then
        kubectl create namespace velero
    fi

    if [ -f "credentials-velero" ]; then
        kubectl create secret generic velero-credentials \
            --from-file=cloud=credentials-velero \
            -n velero \
            --dry-run=client -o yaml | kubectl apply -f -
    else
        log_warn "credentials-velero file not found, skipping secret creation"
    fi

    kubectl apply -f config/velero/install.yaml
    kubectl apply -f config/velero/schedules.yaml
}

deploy_etcd_backup() {
    log_info "Deploying etcd backup system..."
    kubectl apply -f config/etcd/snapshot-cronjob.yaml

    log_warn "Remember to create etcd-backup-secrets with AWS credentials"
}

deploy_argocd() {
    log_info "Deploying ArgoCD..."

    if ! kubectl get namespace argocd >/dev/null 2>&1; then
        kubectl create namespace argocd
    fi

    kubectl apply -f config/gitops/argocd/install.yaml
    kubectl apply -f config/gitops/argocd/projects.yaml

    log_info "Waiting for ArgoCD to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

    log_info "ArgoCD admin password:"
    kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
    echo ""
}

deploy_monitoring() {
    log_info "Deploying monitoring stack..."

    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update

    helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
        -f k8s/monitoring/prometheus-values.yaml \
        -n monitoring \
        --create-namespace
}

deploy_gitlab() {
    log_info "Deploying GitLab..."

    log_warn "Checking if gitlab/infrastructure/secrets-template.yaml has been configured..."
    if kubectl get secret gitlab-postgres-secret -n gitlab >/dev/null 2>&1; then
        log_info "GitLab secrets found, proceeding with deployment"

        helm repo add gitlab https://charts.gitlab.io/
        helm repo update

        helm upgrade --install gitlab gitlab/gitlab \
            -f gitlab/infrastructure/values-production.yaml \
            -n gitlab \
            --create-namespace \
            --timeout 15m
    else
        log_warn "GitLab secrets not configured. Please configure gitlab/infrastructure/secrets-template.yaml first"
        log_warn "Skipping GitLab deployment"
    fi
}

deploy_gitlab_runners() {
    log_info "Deploying GitLab runners..."

    helm repo add gitlab https://charts.gitlab.io/
    helm repo update

    helm upgrade --install gitlab-runner gitlab/gitlab-runner \
        -f gitlab/runners/values-runners.yaml \
        -n gitlab-runners \
        --create-namespace
}

main() {
    log_info "Starting full stack deployment..."

    check_prerequisites
    deploy_namespaces
    deploy_core_resources
    deploy_networking
    deploy_velero
    deploy_etcd_backup
    deploy_argocd
    deploy_monitoring

    # Optional: Deploy GitLab (comment out if not needed initially)
    # deploy_gitlab
    # deploy_gitlab_runners

    log_info "Deployment completed successfully!"
    log_info "ArgoCD URL: https://argocd.company.com"
    log_info "Grafana URL: https://grafana.company.com"
}

main "$@"
