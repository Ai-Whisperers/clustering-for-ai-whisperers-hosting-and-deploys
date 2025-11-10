# etcd Snapshot Configuration
Doc-Type: Configuration Guide · Version 1.0 · Updated 2025-11-10 · AI Whisperers

etcd is the key-value store backing Kubernetes cluster state. Regular snapshots ensure point-in-time recovery of cluster configuration, secrets, and resource definitions. This configuration automates snapshot creation, encryption, and retention management. Snapshots capture the entire cluster state and enable recovery from catastrophic failures independent of Velero.

---

```toon
etcd_backup:
  version: "3.5.10"

  snapshot_schedule:
    full_snapshot:
      interval: "4h"
      retention_count: 48
      retention_days: 7
      compress: true
      encrypt: true

  storage:
    local_path: /var/lib/etcd/snapshots
    remote_backup:
      enabled: true
      provider: s3
      bucket: k8s-etcd-snapshots
      prefix: cluster-01
      region: us-east-1

  encryption:
    enabled: true
    key_provider: kms
    kms_key_id: arn:aws:kms:us-east-1:xxx:key/xxx

  endpoints:
    - https://127.0.0.1:2379

  certificates:
    ca_cert: /etc/kubernetes/pki/etcd/ca.crt
    cert: /etc/kubernetes/pki/etcd/server.crt
    key: /etc/kubernetes/pki/etcd/server.key

  health_check:
    enabled: true
    interval: 5m
    alert_on_failure: true
```
