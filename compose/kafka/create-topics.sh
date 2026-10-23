#!/bin/sh
# Creates the event and dead-letter topics on the local broker, mirroring the
# Kubernetes platform chart. Idempotent: existing topics are left as they are.
set -eu

topics=/opt/kafka/bin/kafka-topics.sh

for topic in $EVENT_TOPICS; do
  "$topics" --bootstrap-server "$BOOTSTRAP" --create --if-not-exists \
    --topic "$topic" --partitions "$PARTITIONS" --replication-factor 1 \
    --config retention.ms="$RETENTION_MS"
done

for topic in $DEAD_LETTER_TOPICS; do
  "$topics" --bootstrap-server "$BOOTSTRAP" --create --if-not-exists \
    --topic "$topic" --partitions 1 --replication-factor 1 \
    --config retention.ms="$RETENTION_MS"
done

"$topics" --bootstrap-server "$BOOTSTRAP" --list
