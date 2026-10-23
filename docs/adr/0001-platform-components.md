# 1. Platform components for Kubernetes

- **Status:** Accepted
- **Date:** 2026-10-23

## Context

CompanyCentral needs PostgreSQL, RabbitMQ, an Ingress with TLS, metrics and
central logs in a cloud-hosted cluster whose provider is not chosen yet. The
team is two people, so components must be cheap to run and to operate, and
should not tie us to one provider.

## Decision

| Need | Choice | Why |
|---|---|---|
| PostgreSQL | **CloudNativePG** operator, one cluster per environment, one database and two roles per service | Declarative databases and roles, failover, backups later; no provider lock-in |
| RabbitMQ | **RabbitMQ Cluster Operator** + **Messaging Topology Operator** | Official operators; vhost, users and permissions as resources |
| Ingress | **Traefik** with standard `Ingress` resources | Maintained (ingress-nginx is retired), cloud-neutral, can grow into gateway duties |
| TLS | **cert-manager** + Let's Encrypt (HTTP-01) | Free, automatic renewal |
| Metrics | **kube-prometheus-stack** with ServiceMonitors | Standard Prometheus/Grafana setup |
| Logs | **Loki** (single binary) + **Grafana Alloy** | Promtail is deprecated; Alloy is its successor |
| Charts | One generic `service` chart with per-workload values | Seven similar workloads, one template to maintain |
| Secrets | Created by a script from random values, never in Git | No secret store yet; Sealed/External Secrets later |

Managed cloud databases or brokers are a later option. Services only see
connection URLs, so switching needs no code change.

## Consequences

- Operators must be installed once per cluster (k8s/README.md).
- One PostgreSQL cluster per environment hosts several service databases: database-per-service is
  enforced through separate databases and credentials, not separate servers.
- Bitnami charts are deliberately not used because of their 2025 licensing and
  image distribution changes.
