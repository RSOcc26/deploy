#!/bin/sh
# Creates one RabbitMQ user per service through the management API and gives
# it access to the companycentral vhost only. Idempotent: safe to run again.
set -eu

for svc in $SERVICES; do
  upper=$(echo "$svc" | tr '[:lower:]' '[:upper:]')
  password=$(printenv "${upper}_MQ_PASSWORD")
  curl -fsS -u "admin:${RABBITMQ_ADMIN_PASSWORD}" -X PUT \
    -H 'content-type: application/json' \
    -d "{\"password\":\"${password}\",\"tags\":\"\"}" \
    "${RABBITMQ_API}/users/${svc}"
  curl -fsS -u "admin:${RABBITMQ_ADMIN_PASSWORD}" -X PUT \
    -H 'content-type: application/json' \
    -d '{"configure":".*","write":".*","read":".*"}' \
    "${RABBITMQ_API}/permissions/companycentral/${svc}"
  echo "RabbitMQ user ${svc} ready"
done
