# Monitoring and logging

> **Status:** values prepared and rendered with `helm template`; not installed yet.

| Component | Chart | Values |
|---|---|---|
| Prometheus, Grafana, kube-state-metrics, node exporter | `prometheus-community/kube-prometheus-stack` 92.11.0 | [kube-prometheus-stack.values.yaml](kube-prometheus-stack.values.yaml) |
| Loki (log storage) | `grafana/loki` 7.5.0 | [loki.values.yaml](loki.values.yaml) |
| Alloy (log collection) | `grafana/alloy` 1.14.2 | [alloy.values.yaml](alloy.values.yaml) |

```sh
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

kubectl -n monitoring create secret generic grafana-admin \
  --from-literal=admin-user=admin --from-literal=admin-password="$(openssl rand -hex 16)"

helm upgrade --install monitoring prometheus-community/kube-prometheus-stack --version 92.11.0 \
  -n monitoring -f monitoring/kube-prometheus-stack.values.yaml
helm upgrade --install loki grafana/loki --version 7.5.0 \
  -n monitoring -f monitoring/loki.values.yaml
helm upgrade --install alloy grafana/alloy --version 1.14.2 \
  -n monitoring -f monitoring/alloy.values.yaml
```

Grafana is not exposed publicly; use
`kubectl -n monitoring port-forward svc/monitoring-grafana 3000:80`.

## What the services must provide

- `GET /metrics` in Prometheus format (scraped through the ServiceMonitor that
  the `service` chart creates).
- JSON logs on stdout with `level`, `service`, `tenantId`, `correlationId`.
  Only `level` becomes a Loki label; search the rest with LogQL `| json`.

## Planned

- Dashboards per service (request rate, errors, latency, outbox backlog,
  consumer lag) committed as JSON.
- Alert rules once there is somewhere to send alerts.
