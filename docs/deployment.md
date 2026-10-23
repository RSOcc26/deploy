# Deployment

> **Status:** documented and statically validated; not yet run end to end.
> Service images do not exist yet, and no cluster has been provisioned.

Background: [architecture §8](https://github.com/RSOcc26/.github/blob/main/docs/architecture.md#8-deployment),
[ADR-0009](https://github.com/RSOcc26/.github/blob/main/docs/adr/0009-kubernetes-helm-ghcr.md),
[deploy ADR-0001](adr/0001-platform-components.md).

## Environments

| Environment | Where | Namespace | Images |
|---|---|---|---|
| local | Docker Compose on a laptop | n/a | built locally or `ghcr.io/rsocc26/*:main` |
| dev | Kubernetes | `companycentral-dev` | `:main` (moving tag) |
| prod | Kubernetes, public URL | `companycentral-prod` | immutable tags pinned in `helm/values/prod/` |

dev and prod may share one cluster to save cost.

## Local development

```sh
cd compose
cp .env.example .env        # replace every placeholder password
docker compose up -d        # PostgreSQL and RabbitMQ
docker compose ps           # wait until healthy
```

- PostgreSQL on `localhost:5432`. Per service: database `<svc>`, roles
  `<svc>_migrator` (owns the schema, runs migrations) and `<svc>_app` (runtime,
  no `BYPASSRLS`). The init script runs only when the volume is first created;
  `docker compose down -v` resets it (and deletes all local data).
- RabbitMQ on `localhost:5672`, management UI on <http://localhost:15672>
  (user `admin`). Vhost `companycentral`, one user per service.
- Run services from their repositories with their `.env` pointing here, using
  the passwords from `compose/.env`.

Full stack from images (once they are published):

```sh
mkdir -p .local && openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 \
  -out .local/tenant-context-key.pem
docker compose --profile apps up -d
```

| URL | What |
|---|---|
| <http://localhost:8081> | web |
| <http://localhost:8080/api/...> | gateway |
| <http://localhost:3001> … `3005` | identity, access, workflow, inventory, production (direct, for debugging) |

## Database privileges and migrations

The infrastructure creates databases and roles only. Each service's **first
migration** (run as `<svc>_migrator`) must:

1. create its tables, each tenant-owned table with `tenant_id`;
2. `ENABLE` and `FORCE ROW LEVEL SECURITY` with a policy on
   `current_setting('app.tenant_id')`;
3. `GRANT SELECT, INSERT, UPDATE, DELETE` on its tables and `USAGE` on its
   sequences to `<svc>_app`, and set matching `ALTER DEFAULT PRIVILEGES`.

In Kubernetes the `service` chart can run migrations as a Helm pre-install /
pre-upgrade Job (`migrations.enabled: true`) once the image provides
`npm run migrate`.

## Cloud deployment

Prerequisites: a Kubernetes cluster, `kubectl`, `helm`, a DNS name.
**Choosing the provider and creating the cluster need a separate decision**,
because they cost money.

1. **Bootstrap the cluster once**: namespaces, Traefik, cert-manager,
   CloudNativePG and the RabbitMQ operators. See [k8s/README.md](../k8s/README.md).
2. **Point DNS** at the Traefik LoadBalancer address.
3. **Create secrets** for the environment (random, never in Git; existing
   ones are kept):

   ```sh
   scripts/create-secrets.sh companycentral-dev
   ```

   Creates per service: `pg-<svc>-migrator`, `pg-<svc>-app` (roles for
   CloudNativePG), `<svc>-database` (`url`, `migration-url`),
   `mq-<svc>-credentials` (RabbitMQ user) and `<svc>-rabbitmq` (`url`); plus
   `gateway-tenant-context-key`.

4. **Images:** GHCR packages must be public, or add an `imagePullSecrets`
   entry with a read-only token.
5. **Deploy:**

   ```sh
   PUBLIC_HOST=dev.example.org ACME_EMAIL=you@example.org scripts/deploy.sh dev
   scripts/deploy.sh dev service-workflow     # one workload only
   ```

   Order: `platform` (PostgreSQL, RabbitMQ) → every workload → `edge`
   (Ingress and certificate).

6. **Verify:** `kubectl -n companycentral-dev get pods`, then open
   `https://<host>/` and `https://<host>/api/...`.

### Releasing to production

1. A service merges to `main`; CI publishes `ghcr.io/rsocc26/<repo>:sha-<sha>`.
2. A pull request in this repository sets `image.tag` in
   `helm/values/prod/<workload>.yaml`.
3. After merge: `scripts/deploy.sh prod <workload>` (automated by a deploy
   workflow later).

## Configuration and secrets

- Non-secret settings: `env` in the values files → ConfigMap.
- Secrets: `secretEnv` references to Secrets created by
  `scripts/create-secrets.sh`. Values files never contain credentials.
- Later options: Sealed Secrets or External Secrets Operator, once there is a
  secret store.

## Monitoring and logging

See [monitoring/README.md](../monitoring/README.md). The `service` chart creates
a `ServiceMonitor` per workload when `metrics.serviceMonitor.enabled` is true
(on in dev and prod values, off for web).

## CI/CD (target)

| Stage | Where | Status |
|---|---|---|
| Lint, test, build | `RSOcc26/.github` reusable CI | pending PR |
| Image build and push to GHCR | `RSOcc26/.github` reusable publish workflow | pending PR |
| Chart lint and render | this repository's `validate` workflow | pending PR |
| Helm deploy | workflow in this repository, triggered by merged tag bumps | planned (needs a cluster and credentials) |
