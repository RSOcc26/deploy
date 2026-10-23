#!/usr/bin/env bash
# Generates random credentials for one environment and stores them as
# Kubernetes Secrets in its namespace. Nothing is written to disk or Git.
# Existing Secrets are never overwritten, so it is safe to run again.
#
# Usage: scripts/create-secrets.sh <namespace>
# Requires: kubectl (pointing at the right cluster), openssl.
set -euo pipefail

ns=${1:?usage: scripts/create-secrets.sh <namespace>}
services=(identity access workflow inventory production)
pg_host="companycentral-pg-rw.${ns}.svc"
mq_host="companycentral-mq.${ns}.svc"

exists() { kubectl -n "$ns" get secret "$1" >/dev/null 2>&1; }
random() { openssl rand -hex 24; }

kubectl get namespace "$ns" >/dev/null 2>&1 || kubectl create namespace "$ns"

for svc in "${services[@]}"; do
  if exists "${svc}-database"; then
    echo "${svc}: secrets exist, skipped"
    continue
  fi
  migrator_pw=$(random)
  app_pw=$(random)
  mq_pw=$(random)

  # Role credentials read by CloudNativePG (managed roles).
  kubectl -n "$ns" create secret generic "pg-${svc}-migrator" --type=kubernetes.io/basic-auth \
    --from-literal=username="${svc}_migrator" --from-file=password=<(printf %s "$migrator_pw")
  kubectl -n "$ns" create secret generic "pg-${svc}-app" --type=kubernetes.io/basic-auth \
    --from-literal=username="${svc}_app" --from-file=password=<(printf %s "$app_pw")
  kubectl -n "$ns" label secret "pg-${svc}-migrator" "pg-${svc}-app" cnpg.io/reload=true >/dev/null

  # Connection URLs read by the service.
  kubectl -n "$ns" create secret generic "${svc}-database" \
    --from-file=url=<(printf 'postgres://%s_app:%s@%s:5432/%s' "$svc" "$app_pw" "$pg_host" "$svc") \
    --from-file=migration-url=<(printf 'postgres://%s_migrator:%s@%s:5432/%s' "$svc" "$migrator_pw" "$pg_host" "$svc")

  # RabbitMQ user (Messaging Topology Operator) and the service's URL.
  kubectl -n "$ns" create secret generic "mq-${svc}-credentials" \
    --from-literal=username="$svc" --from-file=password=<(printf %s "$mq_pw")
  kubectl -n "$ns" create secret generic "${svc}-rabbitmq" \
    --from-file=url=<(printf 'amqp://%s:%s@%s:5672/companycentral' "$svc" "$mq_pw" "$mq_host")

  echo "${svc}: secrets created"
done

# Key the gateway signs the tenant context with (organization ADR-0001).
if exists gateway-tenant-context-key; then
  echo "gateway: signing key exists, skipped"
else
  kubectl -n "$ns" create secret generic gateway-tenant-context-key \
    --from-file=tenant-context-key.pem=<(openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256)
  echo "gateway: signing key created"
fi
