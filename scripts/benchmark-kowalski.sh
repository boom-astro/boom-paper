#!/usr/bin/env bash

COMPOSE_CONFIG="config/kowalski/compose.yaml"

# A function that returns the current date and time
current_datetime() {
    date +%Y%m%d_%H%M%S
}

# Create some files that must exist for Kowalski to work
echo benchmarking > kowalski/version.txt
echo thisisarandomkeyfortesting > kowalski/mongo_key.yaml

# Remove any existing containers
docker compose -f $COMPOSE_CONFIG down
docker compose -f config/boom/compose.yaml down

# Spin up services with Docker Compose
mkdir -p logs/kowalski
docker compose -f $COMPOSE_CONFIG up --build -d

# Send the logs to file so we can analyze later
docker compose -f $COMPOSE_CONFIG logs producer > logs/kowalski/producer.log &

# Detect that all alerts have been processed
# First wait for the file to be created
echo "Waiting for Dask cluster log file to be created"
while [ ! -f logs/kowalski/dask_cluster.log ]; do
    sleep 1
done

# Send ingester container stats to log file
docker compose -f $COMPOSE_CONFIG stats ingester --format json \
    > logs/kowalski/ingester.stats.log &

EXPECTED_ALERTS=29142

# instead just look for log lines like `number of filters passed: ...`
echo "$(current_datetime) Waiting for all alerts to be processed"
while [ $(docker compose -f $COMPOSE_CONFIG exec ingester /bin/bash -c "grep 'number of filters passed' /kowalski/logs/dask_cluster.log | wc -l") -lt $EXPECTED_ALERTS ]; do
    sleep 1
done

echo "$(current_datetime) All tasks completed; shutting down Kowalski services"

# Shut down the services
docker compose -f $COMPOSE_CONFIG down

exit 0
