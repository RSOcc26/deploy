# deploy

Infrastructure and deployment configuration for **CompanyCentral**: local
Docker Compose, Kubernetes bootstrap, Helm charts, per-environment values,
PostgreSQL and Apache Kafka, Ingress and TLS, monitoring and logging.

Part of **CompanyCentral**, a multi-tenant, cloud-native platform built for
the *Cloud Computing Services* course (RSO 2026/27, FRI UL).
See the [architecture](https://github.com/RSOcc26/.github/blob/main/docs/architecture.md) and the
[RSOcc26 organization](https://github.com/RSOcc26) for the other repositories.

> **Status:** scaffold. The Compose file and Helm charts validate (`docker
> compose config`, `helm lint`, kubeconform). Nothing is deployed yet: no
> service images exist and no cluster has been provisioned.

This repository holds **no application code**, and application repositories
hold no deployment configuration (see the
[architecture, §8](https://github.com/RSOcc26/.github/blob/main/docs/architecture.md#8-deployment)).

## Layout

```
compose/              local development stack (Docker Compose)
  compose.yaml        PostgreSQL, Kafka, Keycloak; services, gateway and web under the "apps" profile
  .env.example        local credentials (placeholders)
  postgres/init/      creates one database, migration role and runtime role per service
  kafka/              creates the event and dead-letter topics
  keycloak/           OIDC realm (companycentral) imported on first start
k8s/                  one-time cluster bootstrap: namespaces, Ingress controller, operators
helm/
  charts/
    service/          generic chart for every service, the gateway and web
    platform/         PostgreSQL (CloudNativePG) and Kafka (Strimzi) per environment
    edge/             Ingress, TLS (cert-manager ClusterIssuer)
  values/
    common/           per workload, shared by all environments
    dev/              development overrides
    prod/             production overrides (image tags pinned here)
monitoring/           kube-prometheus-stack, Loki and Alloy values
scripts/
  create-secrets.sh   generates credentials as Kubernetes Secrets (never in Git)
  deploy.sh           helm upgrade --install for one environment
  lint.sh             helm lint + template for every chart and environment
terraform/            planned: cluster and DNS provisioning
docs/
  deployment.md       how to run locally and deploy to a cluster
  adr/                decisions specific to deployment
```

## Quick start (local)

```sh
cd compose
cp .env.example .env                 # replace every placeholder
docker compose up -d                 # PostgreSQL :5432, Kafka :9094, Keycloak :8180
```

Run a service from its own repository against this stack, using the URLs in
that repository's `.env.example`. Full instructions, including the `apps`
profile and the cloud deployment, are in [docs/deployment.md](docs/deployment.md).

## Validation

```sh
scripts/lint.sh                                   # requires helm
docker compose -f compose/compose.yaml --env-file compose/.env.example config -q
```

## Contributing

- Branch from `main` (`feat/…`, `fix/…`, `chore/…`) and open a pull request.
- Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/).
- Pull requests need a review from a code owner and passing checks; they are squash-merged.
- Record notable changes in `CHANGELOG.md`.

## License

[MIT](LICENSE)
