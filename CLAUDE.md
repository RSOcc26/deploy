# CLAUDE.md

Guidance for AI coding agents (Claude Code and others) working in this
repository. The shared, organization-wide guidance lives only in the `.github`
repository and is imported below; this file adds what is specific to this
repository.

@../.github/CLAUDE.md

If the import above did not load (no `.github` clone next to this repository,
or an agent without `@` imports), read
[.github/CLAUDE.md](https://github.com/RSOcc26/.github/blob/main/CLAUDE.md)
before making changes.

## This repository: `deploy`

Infrastructure and deployment configuration only: Docker Compose for local
development (`compose/`), cluster bootstrap (`k8s/`), Helm charts and
per-environment values (`helm/`), monitoring and logging values
(`monitoring/`), and helper scripts (`scripts/`). No application code lives
here, and no deployment configuration lives in the service repositories.

Never commit credentials: Compose reads them from a git-ignored `.env`, and
Kubernetes Secrets are created by `scripts/create-secrets.sh`. Applying
anything to a real cluster, or creating cloud resources (which may cost money),
needs explicit approval. Run `scripts/lint.sh` after changing charts or values.

Layout: `compose/`, `k8s/`, `helm/charts/{service,platform,edge}/`,
`helm/values/{common,dev,prod}/`, `monitoring/`, `scripts/`, `terraform/`
(planned), `docs/` (`deployment.md`, `adr/`).
