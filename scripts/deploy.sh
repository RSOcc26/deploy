#!/usr/bin/env bash
# Deploys CompanyCentral to one environment with Helm.
#
# Usage: scripts/deploy.sh <dev|prod> [workload ...]
#   Without workloads, deploys the platform, every workload and the edge.
#   Image tags come from helm/values/<env>/<workload>.yaml.
#
# Requires: helm, kubectl; the operators from k8s/README.md; Secrets from
# scripts/create-secrets.sh; PUBLIC_HOST and ACME_EMAIL for the edge release.
set -euo pipefail

env=${1:?usage: scripts/deploy.sh <dev|prod> [workload ...]}
shift
case "$env" in dev|prod) ;; *) echo "unknown environment: $env" >&2; exit 1 ;; esac

root=$(cd "$(dirname "$0")/.." && pwd)
values="$root/helm/values"
ns="companycentral-${env}"
all=(service-identity service-access service-workflow service-inventory service-production gateway web)
workloads=("$@")

if [ ${#workloads[@]} -eq 0 ]; then
  helm upgrade --install platform "$root/helm/charts/platform" -n "$ns" --create-namespace \
    -f "$values/$env/platform.yaml" --wait
  workloads=("${all[@]}")
  deploy_edge=true
else
  deploy_edge=false
fi

for w in "${workloads[@]}"; do
  helm upgrade --install "$w" "$root/helm/charts/service" -n "$ns" \
    -f "$values/common/$w.yaml" -f "$values/$env/$w.yaml" \
    --wait --timeout 5m
done

if [ "$deploy_edge" = true ]; then
  helm upgrade --install edge "$root/helm/charts/edge" -n "$ns" \
    -f "$values/$env/edge.yaml" \
    --set host="${PUBLIC_HOST:?set PUBLIC_HOST}" \
    --set clusterIssuer.email="${ACME_EMAIL:?set ACME_EMAIL}"
fi
