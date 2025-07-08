#!/usr/bin/env bash

COMPOSE_CONFIG="config/kowalski/compose.yaml"

# Create some files that must exist for Kowalski to work
echo benchmarking > kowalski/version.txt
echo thisisarandomkeyfortesting > kowalski/mongo_key.yaml

# Remove any existing containers
docker compose -f $COMPOSE_CONFIG down
docker compose -f config/boom/compose.yaml down

# Spin up services with Docker Compose
docker compose -f $COMPOSE_CONFIG up --build -d

# Detect that all alerts have been processed
# First wait for the file to be created
echo "Waiting for Dask cluster log file to be created"
while [ ! -f logs/kowalski/dask_cluster.log ]; do
    sleep 1
done

# Send ingester container stats to log file
docker compose -f $COMPOSE_CONFIG stats ingester --format json \
    > logs/kowalski/ingester.stats.log &

# Simply look for 'MLing' a certain number of times
EXPECTED_ALERTS=29124
echo "Waiting for all tasks to complete"
while [ $(grep -c MLing logs/kowalski/dask_cluster.log) -lt $EXPECTED_ALERTS ]; do
    sleep 1
done

# Shut down the services
docker compose -f $COMPOSE_CONFIG down
