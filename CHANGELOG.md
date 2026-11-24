# Changelog

All notable changes to this repository are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and the project uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- Initial repository scaffold.
- `keycloak` Helm chart: Keycloak in production mode at `https://<host>/idp`,
  on the platform PostgreSQL (database `keycloak`), importing the
  `companycentral` realm and login theme. The realm and theme moved from
  `compose/keycloak/` to `helm/charts/keycloak/files/`, shared by both.
- `create-secrets.sh` also creates the Keycloak database roles,
  `keycloak-admin` and `identity-idp-client`.
- `edge` routes `/idp` to Keycloak. dev uses Let's Encrypt production by
  default and creates the `letsencrypt-prod` issuer; prod reuses it.
- OIDC settings for `gateway`, `web` and `service-identity` (Keycloak in the
  cluster); `service-identity` also gets `DATABASE_MIGRATION_URL` and
  `IDP_CLIENT_SECRET`.

### Changed

- dev ServiceMonitors are off until kube-prometheus-stack is installed.
- Keycloak (OIDC provider, ADR-0002) in the local Compose stack with the
  `companycentral` realm and the public `web` client.
- Audience mapper on the `web` client: access tokens carry `aud: gateway`,
  which the gateway requires. The realm is imported only on first start, so an
  existing local Keycloak needs the mapper added in the admin console or a
  fresh `keycloak-data` volume.
- CompanyCentral Keycloak login theme (`compose/keycloak/themes/companycentral`):
  our own layout, styles and sl/en texts on top of Keycloak's unstyled base
  theme, used for sign-in, registration, password reset and every other
  login-flow page. Set as the realm's `loginTheme`; mounted read-only in
  Compose. Keycloak still handles all credentials.
- Realm: `platform-admin` role and the confidential `service-identity` client
  whose service account may manage users (ADR-0003). Its secret is set on
  import from `IDENTITY_IDP_CLIENT_SECRET` in `.env`.
- Realm: public `api-docs` client (authorization code + PKCE, audience
  `gateway`) for the gateway's Swagger UI; redirect
  `http://localhost:8080/api-docs/ui/static/oauth2-redirect.html`.
- Compose: OIDC settings for the gateway (`OIDC_ISSUER`, `OIDC_AUDIENCE`,
  `OIDC_JWKS_URL`) and the web (`OIDC_AUTHORITY`, `OIDC_CLIENT_ID`).
- Compose: `web` proxies `/api` to the gateway (`GATEWAY_URL`), so the app on
  `localhost:8081` works like behind the Ingress.
