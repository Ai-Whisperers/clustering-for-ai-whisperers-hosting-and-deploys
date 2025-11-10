# Docker Desktop Kubernetes Configuration
Doc-Type: Configuration Guide · Version 1.0 · Updated 2025-11-10 · AI Whisperers

Docker Desktop provides a local Kubernetes cluster for development and testing. This configuration bridges local development with production-grade tooling, enabling developers to test GitOps workflows, backup procedures, and cluster configurations before production deployment. Settings optimize resource usage while maintaining functional parity with production environments.

---

```toon
docker_desktop:
  kubernetes:
    enabled: true
    version: "1.28.2"

  resources:
    cpus: 4
    memory: 8GB
    swap: 2GB
    disk: 100GB

  contexts:
    development:
      cluster: docker-desktop
      user: docker-desktop
      namespace: dev

    local_testing:
      cluster: docker-desktop
      user: docker-desktop
      namespace: testing

  extensions:
    recommended:
      - kubernetes-dashboard
      - lens
      - portainer

  settings:
    features:
      kubernetes: true
      wsl_integration: true
      buildkit: true
      compose_v2: true

    experimental:
      vpnkit_mtu: 1500
      host_networking: false

  local_registry:
    enabled: true
    port: 5000
    storage: 20GB

  port_forwarding:
    - {service: argocd-server, namespace: argocd, port: 8080}
    - {service: gitlab-webservice, namespace: gitlab, port: 80}
    - {service: prometheus-server, namespace: monitoring, port: 9090}
    - {service: grafana, namespace: monitoring, port: 3000}

  volume_mounts:
    enabled: true
    paths:
      - /c/Users/Gestalt/Desktop/services of customer analysis/n SERVICES/k8s-cluster
```
