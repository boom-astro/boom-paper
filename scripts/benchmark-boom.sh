#!/usr/bin/env bash

COMPOSE_CONFIG="config/boom/compose.yaml"

# Remove any existing containers
docker compose -f $COMPOSE_CONFIG down

# Spin up BOOM services with Docker Compose
docker compose -f $COMPOSE_CONFIG up -d

# Send the logs to file so we can analyze later
mkdir -p logs/boom
docker compose -f $COMPOSE_CONFIG logs producer > logs/boom/producer.log &
docker compose -f $COMPOSE_CONFIG logs consumer -f > logs/boom/consumer.log &
docker compose -f $COMPOSE_CONFIG logs scheduler -f | tee logs/boom/scheduler.log

# TODO: Wait until the workers are all done
# Maybe we should watch an output stream and wait for all alerts to be
# received?
# Read the scheduler logs and wait for the filter worker to have zero tasks
# left

# Shut down the BOOM services
docker compose -f $COMPOSE_CONFIG down
