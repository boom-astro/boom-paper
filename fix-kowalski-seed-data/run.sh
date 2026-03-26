#!/usr/bin/env bash

COMPOSE_CONFIG="fix-kowalski-seed-data/compose.yaml"

# A function that returns the current date and time
current_datetime() {
    TZ=utc date "+%Y-%m-%d %H:%M:%S"
}

rm -f data/alerts/tmp/*
rm -f data/alerts/kowalski.ZTF_alerts_aux.dump.gz

export DB_NAME=kowalski

# Remove any existing containers
docker compose -f $COMPOSE_CONFIG down

# Spin up BOOM services with Docker Compose
docker compose -f $COMPOSE_CONFIG up --build -d

# Send the logs to file so we can analyze later
LOGS_DIR="fix-kowalski-seed-data/logs"
mkdir -p $LOGS_DIR
docker compose -f $COMPOSE_CONFIG logs -f --no-color mongo-init > $LOGS_DIR/mongo-init.log 2>&1 &
LOGS_PID=$!

# Simply wait until mongo-init finishes, then check its status
echo "$(current_datetime) - Waiting for mongo-init to complete"
docker compose -f $COMPOSE_CONFIG wait mongo-init >/dev/null 2>&1 || true

# Get the mongo-init exit code directly from Docker inspect as source of truth
MONGO_INIT_CONTAINER_ID=$(docker compose -f $COMPOSE_CONFIG ps -a -q mongo-init)
MONGO_INIT_EXIT=$(docker inspect --format '{{.State.ExitCode}}' "$MONGO_INIT_CONTAINER_ID" 2>/dev/null || echo "")

# Stop background log follower and write a final complete log snapshot
if [ -n "$LOGS_PID" ]; then
    kill "$LOGS_PID" >/dev/null 2>&1 || true
fi
docker compose -f $COMPOSE_CONFIG logs --no-color mongo-init > $LOGS_DIR/mongo-init.log 2>&1 || true

if [ -z "$MONGO_INIT_EXIT" ]; then
    echo "$(current_datetime) - Error: Could not determine mongo-init exit status; Containers left running for inspection"
    exit 1
fi

if [ "$MONGO_INIT_EXIT" -ne 0 ]; then
    echo "$(current_datetime) - Debug: inspected exit=$MONGO_INIT_EXIT"
    echo "$(current_datetime) - Error: mongo-init exited with non-zero status; Containers left running for inspection"
    exit 1
else
    echo "$(current_datetime) - Debug: inspected exit=$MONGO_INIT_EXIT"
    echo "$(current_datetime) - All tasks completed successfully; shutting down services"
    docker compose -f $COMPOSE_CONFIG down
fi

exit 0
