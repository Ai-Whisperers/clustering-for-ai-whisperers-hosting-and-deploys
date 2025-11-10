# GitLab Production Infrastructure
Doc-Type: Infrastructure Guide · Version 1.0 · Updated 2025-11-10 · AI Whisperers

GitLab serves as the central platform for source control, CI/CD, and GitOps workflows. This production deployment runs on Kubernetes with high availability, automated backups, and integrated runners. The infrastructure supports multi-project pipelines, container registry, and ArgoCD integration for continuous deployment. All configurations are managed declaratively through GitOps principles.

---

```toon
gitlab_infrastructure:
  version: "16.7.0"
  edition: enterprise

  deployment:
    namespace: gitlab
    architecture: ha
    components:
      webservice:
        replicas: 3
        resources:
          requests: {cpu: 1000m, memory: 2Gi}
          limits: {cpu: 2000m, memory: 4Gi}

      sidekiq:
        replicas: 2
        resources:
          requests: {cpu: 500m, memory: 1Gi}
          limits: {cpu: 1000m, memory: 2Gi}

      gitaly:
        replicas: 3
        storage_class: fast-ssd
        storage_size: 500Gi

  postgres:
    version: "14.9"
    ha_mode: true
    replicas: 3
    storage_size: 200Gi
    backup_schedule: "0 1 * * *"

  redis:
    version: "7.0"
    ha_mode: true
    replicas: 3
    persistence: true

  object_storage:
    provider: s3
    buckets:
      artifacts: gitlab-artifacts
      lfs: gitlab-lfs
      packages: gitlab-packages
      uploads: gitlab-uploads
      registry: gitlab-registry
      backups: gitlab-backups

  ingress:
    enabled: true
    class: nginx
    hostname: gitlab.company.com
    tls:
      enabled: true
      issuer: letsencrypt-prod

  runners:
    docker:
      replicas: 5
      concurrent: 10
      resources:
        requests: {cpu: 500m, memory: 1Gi}
        limits: {cpu: 2000m, memory: 4Gi}

    kubernetes:
      replicas: 3
      namespace: gitlab-runners
      service_account: gitlab-runner

  monitoring:
    prometheus: true
    grafana_dashboards: true
    alerts_enabled: true

  backup:
    enabled: true
    schedule: "0 2 * * *"
    keep_daily: 7
    keep_weekly: 4
    keep_monthly: 12
    storage: s3://gitlab-backups

  gitops_integration:
    argocd:
      enabled: true
      webhook_url: https://argocd.company.com/api/webhook
      auto_sync: true
```
