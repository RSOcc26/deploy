#!/usr/bin/env bash
# Lints and renders every chart with every environment's values.
# Used locally and in CI. Requires: helm.
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
values="$root/helm/values"
charts="$root/helm/charts"
out=$(mktemp -d)
trap 'rm -rf "$out"' EXIT

# Placeholders only for rendering; real values come from the environment.
render_args=(--set image.tag=lint)
edge_args=(--set host=companycentral.example.org --set clusterIssuer.email=ops@example.org)

for env in dev prod; do
  helm lint "$charts/platform" -f "$values/$env/platform.yaml"
  helm template platform "$charts/platform" -f "$values/$env/platform.yaml" > "$out/$env-platform.yaml"

  helm lint "$charts/edge" -f "$values/$env/edge.yaml" "${edge_args[@]}"
  helm template edge "$charts/edge" -f "$values/$env/edge.yaml" "${edge_args[@]}" > "$out/$env-edge.yaml"

  for file in "$values"/common/*.yaml; do
    w=$(basename "$file" .yaml)
    helm lint "$charts/service" -f "$file" -f "$values/$env/$w.yaml" "${render_args[@]}"
    extra=()
    # Render the migration Job too for workloads that own a database.
    case "$w" in service-*) extra=(--set migrations.enabled=true) ;; esac
    helm template "$w" "$charts/service" -f "$file" -f "$values/$env/$w.yaml" \
      "${render_args[@]}" "${extra[@]}" > "$out/$env-$w.yaml"
  done
done

echo "Rendered manifests:"
ls "$out"
if [ -n "${RENDER_DIR:-}" ]; then
  mkdir -p "$RENDER_DIR" && cp "$out"/*.yaml "$RENDER_DIR"/
fi
