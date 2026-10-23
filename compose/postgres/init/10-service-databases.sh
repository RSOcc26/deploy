#!/bin/sh
# Runs once, when the PostgreSQL volume is first initialized.
# For every service in $SERVICES it creates:
#   - database <svc>
#   - role <svc>_migrator: owns the database and schema, runs migrations
#   - role <svc>_app: runtime role, no ownership, no BYPASSRLS
# Passwords come from <SVC>_MIGRATOR_PASSWORD and <SVC>_APP_PASSWORD.
# Table privileges for <svc>_app are granted by each service's own migrations.
set -eu

for svc in $SERVICES; do
  upper=$(echo "$svc" | tr '[:lower:]' '[:upper:]')
  migrator_pw=$(printenv "${upper}_MIGRATOR_PASSWORD")
  app_pw=$(printenv "${upper}_APP_PASSWORD")

  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname postgres \
    -v db="$svc" -v migrator="${svc}_migrator" -v app="${svc}_app" \
    -v migrator_pw="$migrator_pw" -v app_pw="$app_pw" <<'SQL'
CREATE ROLE :"migrator" LOGIN PASSWORD :'migrator_pw';
CREATE ROLE :"app" LOGIN NOBYPASSRLS PASSWORD :'app_pw';
CREATE DATABASE :"db" OWNER :"migrator";
REVOKE ALL ON DATABASE :"db" FROM PUBLIC;
GRANT CONNECT ON DATABASE :"db" TO :"app";
SQL

  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$svc" \
    -v migrator="${svc}_migrator" -v app="${svc}_app" <<'SQL'
ALTER SCHEMA public OWNER TO :"migrator";
REVOKE ALL ON SCHEMA public FROM PUBLIC;
GRANT USAGE ON SCHEMA public TO :"app";
SQL
done
