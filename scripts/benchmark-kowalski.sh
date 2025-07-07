#!/usr/bin/env bash

COMPOSE_CONFIG="config/kowalski/compose.yaml"

# Remove any existing containers
docker compose -f $COMPOSE_CONFIG down

# Spin up services with Docker Compose
docker compose -f $COMPOSE_CONFIG up -d

# Detect that all alerts have been processed
# We know that for 20250311, there end up being ~639700 lines in the Dask
# cluster log file
# First wait for the file to be created
echo "Waiting for Dask cluster log file to be created"
while [ ! -f logs/kowalski/dask_cluster.log ]; do
    sleep 1
done
EXPECTED_LINES=639700
echo "Waiting for all tasks to complete"
while [ $(wc -l < logs/kowalski/dask_cluster.log) -lt $EXPECTED_LINES ]; do
    sleep 10
done

# Shut down the services
docker compose -f $COMPOSE_CONFIG down
