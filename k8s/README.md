# Cluster bootstrap

One-time setup of a Kubernetes cluster for CompanyCentral: namespaces, the
Ingress controller, cert-manager and the operators that run PostgreSQL and
RabbitMQ. Everything after this is Helm releases from `helm/` (see
[docs/deployment.md](../docs/deployment.md)).

> **Status:** documented, not yet run against a cluster. No cluster exists yet,
> and the provider is not chosen.

Versions are pinned. Upgrade them deliberately, in a pull request.

| Component | Purpose | Chart / manifest | Version |
|---|---|---|---|
| Traefik | Ingress controller (TLS via cert-manager) | `traefik/traefik` | chart 42.1.3 |
| cert-manager | Let's Encrypt certificates | `jetstack/cert-manager` | v1.21.2 |
| CloudNativePG | PostgreSQL operator | `cnpg/cloudnative-pg` | chart 0.29.1 (operator 1.30.1) |
| RabbitMQ Cluster Operator | RabbitMQ brokers | release manifest | v2.23.1 |
| RabbitMQ Messaging Topology Operator | Vhosts, users, permissions as resources | release manifest | v1.20.4 |
| kube-prometheus-stack, Loki, Alloy | Metrics and logs | see [monitoring/](../monitoring/README.md) | |

Why Traefik: the community `ingress-nginx` controller has been retired, and
Traefik is maintained, cloud-neutral and can also act as an API gateway
later (gateway repository, ADR-0001). Any controller that supports standard
`Ingress` works; set `ingressClassName` in the `edge` chart.

## Steps

```sh
kubectl apply -f k8s/namespaces.yaml

helm repo add traefik https://traefik.github.io/charts
helm repo add jetstack https://charts.jetstack.io
helm repo add cnpg https://cloudnative-pg.github.io/charts
helm repo update

# Ingress controller: creates a LoadBalancer Service; point DNS at its address.
helm upgrade --install traefik traefik/traefik --version 42.1.3 \
  -n traefik --create-namespace

# cert-manager with its CRDs
helm upgrade --install cert-manager jetstack/cert-manager --version v1.21.2 \
  -n cert-manager --create-namespace --set crds.enabled=true

# PostgreSQL operator
helm upgrade --install cnpg cnpg/cloudnative-pg --version 0.29.1 \
  -n cnpg-system --create-namespace

# RabbitMQ operators (the topology operator needs cert-manager)
kubectl apply -f https://github.com/rabbitmq/cluster-operator/releases/download/v2.23.1/cluster-operator.yml
kubectl apply -f https://github.com/rabbitmq/messaging-topology-operator/releases/download/v1.20.4/messaging-topology-operator-with-certmanager.yaml
```

Then create the credentials and deploy:

```sh
scripts/create-secrets.sh companycentral-dev
PUBLIC_HOST=dev.example.org ACME_EMAIL=you@example.org scripts/deploy.sh dev
```

## Cost note

The LoadBalancer Service and persistent volumes are billable on most cloud
providers. Do not create a cluster or these resources on a paid account
without agreeing on it first.
