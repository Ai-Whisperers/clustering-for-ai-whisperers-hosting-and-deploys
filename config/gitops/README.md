# GitOps Configuration
Doc-Type: Configuration Guide · Version 1.0 · Updated 2025-11-10 · AI Whisperers

GitOps enables declarative cluster management through Git as the single source of truth. ArgoCD continuously monitors Git repositories and synchronizes cluster state with declared configurations. This setup supports multi-environment deployments, automated rollbacks, and audit trails. Production clusters use ArgoCD for its robust reconciliation engine and GitLab integration.

---

```toon
gitops:
  tool: argocd
  version: "2.9.0"

  deployment:
    namespace: argocd
    ha_mode: true
    replicas: 3

  repository_sources:
    gitlab:
      url: https://gitlab.company.com
      type: git
      credentials_secret: gitlab-repo-creds

    helm_charts:
      url: https://charts.company.com
      type: helm
      credentials_secret: helm-repo-creds

  application_sync:
    auto_sync: true
    self_heal: true
    prune: true
    sync_policy:
      retry_limit: 5
      retry_backoff:
        duration: 5s
        factor: 2
        max_duration: 3m

  notifications:
    enabled: true
    integrations:
      - slack
      - gitlab
    triggers:
      - on-deployed
      - on-health-degraded
      - on-sync-failed

  rbac:
    policy_csv: |
      p, role:admin, applications, *, */*, allow
      p, role:developer, applications, get, */*, allow
      p, role:developer, applications, sync, */dev/*, allow
      g, admin-team, role:admin
      g, dev-team, role:developer

  projects:
    production:
      source_repos:
        - https://gitlab.company.com/infrastructure/*
      destinations:
        - namespace: production
          server: https://kubernetes.default.svc
      cluster_resource_whitelist:
        - group: "*"
          kind: "*"

    gitlab:
      source_repos:
        - https://gitlab.company.com/gitlab/*
      destinations:
        - namespace: gitlab
          server: https://kubernetes.default.svc
```
