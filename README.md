# homelab

Personal homelab for learning infrastructure operations.
A Proxmox-based VM lab evolving toward Kubernetes with full observability and GitOps.

## Status

Phase 0: Foundation setup (in progress)

## Stack (planned)

- **Hypervisor**: Proxmox VE 9
- **Provisioning**: Ansible
- **Application**: Go (URL shortener)
- **Containers**: Docker
- **Orchestration**: k3s + Helm + Argo CD
- **Observability**: Prometheus + Grafana + Loki + Tempo
- **CI/CD**: GitHub Actions + ghcr.io

## Architecture

(構成図はPhase 0完了時に追加予定)

## Documentation

- [Architecture](docs/architecture.md)
- [Architecture Decision Records](docs/decisions/)

## License

MIT