#!/usr/bin/env bash

COMPOSE_CONFIG="config/kowalski/compose.yaml"

# Remove any existing containers
docker compose -f $COMPOSE_CONFIG down

# Spin up services with Docker Compose
docker compose -f $COMPOSE_CONFIG up -d

# TODO: Wait until the workers are all done
# Maybe we should watch an output stream and wait for all alerts to be
# received?
# Read the scheduler logs and wait for the filter worker to have zero tasks
# left

# Shut down the services
docker compose -f $COMPOSE_CONFIG down
