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
docker compose -f $COMPOSE_CONFIG logs scheduler -f > logs/boom/scheduler.log &

# Wait until we see "queue is empty" 10 times in the scheduler logs
# This is not foolproof, but it should work for now
# TODO: This should probably look at the filter worker
# We could also potentially look at the size of the queues in Valkey
echo "Waiting for all tasks to complete"
while [ $(grep -c "queue is empty" logs/boom/scheduler.log) -lt 10 ]; do
    sleep 1
done

echo "All tasks completed; shutting down BOOM services"

# Shut down the BOOM services
docker compose -f $COMPOSE_CONFIG down
