# Changelog

All notable changes to this repository are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and the project uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- Repository scaffold.
- Docker Compose stack for local development: PostgreSQL with one database and two roles per service, RabbitMQ with one user per service, and services, gateway and web under the `apps` profile.
- Helm charts: `service` (generic workload), `platform` (CloudNativePG cluster and databases, RabbitMQ cluster, vhost, users and permissions) and `edge` (Ingress and cert-manager ClusterIssuer), with dev and prod values.
- Cluster bootstrap documentation, monitoring and logging values (kube-prometheus-stack, Loki, Alloy).
- Scripts to create secrets, deploy and lint.
