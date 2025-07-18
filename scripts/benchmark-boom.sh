#!/usr/bin/env bash

COMPOSE_CONFIG="config/boom/compose.yaml"

# Logs folder is the first argument to the script
LOGS_DIR=${1:-logs/boom}

# Remove any existing containers
docker compose -f $COMPOSE_CONFIG down
docker compose -f config/kowalski/compose.yaml down

# Spin up BOOM services with Docker Compose
docker compose -f $COMPOSE_CONFIG up --build -d

# Send the logs to file so we can analyze later
mkdir -p $LOGS_DIR
docker compose -f $COMPOSE_CONFIG logs producer > $LOGS_DIR/producer.log &
docker compose -f $COMPOSE_CONFIG logs consumer -f > $LOGS_DIR/consumer.log &
docker compose -f $COMPOSE_CONFIG logs scheduler -f > $LOGS_DIR/scheduler.log &
# Also log stats from containers for later analysis
docker compose -f $COMPOSE_CONFIG stats consumer --format json > $LOGS_DIR/consumer.stats.log &
docker compose -f $COMPOSE_CONFIG stats scheduler --format json > $LOGS_DIR/scheduler.stats.log &

# Wait until we see all alerts with classifications
EXPECTED_ALERTS=29142
echo "Waiting for all tasks to complete"
while [ $(docker compose -f config/boom/compose.yaml exec mongo mongosh "mongodb://mongoadmin:mongoadminsecret@localhost:27017" --quiet --eval "db.getSiblingDB('boom').ZTF_alerts.countDocuments({ classifications: { \$exists: true } })") -lt $EXPECTED_ALERTS ]; do
    sleep 1
done

echo "All tasks completed; shutting down BOOM services"

# Shut down the BOOM services
docker compose -f $COMPOSE_CONFIG down

exit 0
