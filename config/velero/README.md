# Velero Backup & Restore Configuration
Doc-Type: Configuration Guide · Version 1.0 · Updated 2025-11-10 · AI Whisperers

Velero provides disaster recovery and cluster migration capabilities for Kubernetes. This configuration enables automated backups of cluster resources, persistent volumes, and supports point-in-time restoration. Production deployments use S3-compatible storage with scheduled backups running daily for full cluster state and hourly for critical namespaces.

---

```toon
velero:
  version: "1.12.0"

  storage:
    provider: aws
    bucket: k8s-cluster-backups
    region: us-east-1
    credentials_secret: velero-credentials

  backup_schedules:
    full_cluster:
      schedule: "0 2 * * *"
      ttl: 720h
      include_namespaces: "*"
      snapshot_volumes: true

    critical_namespaces:
      schedule: "0 */6 * * *"
      ttl: 168h
      include_namespaces:
        - production
        - gitlab
        - monitoring
      snapshot_volumes: true

  restore_hooks:
    post_restore:
      - init_containers: true
      - exec_timeout: 30m

  volume_snapshot:
    provider: aws
    enable_csi: true

  excluded_resources:
    - events
    - replicasets
    - pods
```
