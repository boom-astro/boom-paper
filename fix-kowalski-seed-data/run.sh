#!/usr/bin/env bash

COMPOSE_CONFIG="fix-kowalski-seed-data/compose.yaml"

# A function that returns the current date and time
current_datetime() {
    TZ=utc date "+%Y-%m-%d %H:%M:%S"
}

export DB_NAME=kowalski

# Remove any existing containers
docker compose -f $COMPOSE_CONFIG down

# Spin up BOOM services with Docker Compose
docker compose -f $COMPOSE_CONFIG up --build -d

# Send the logs to file so we can analyze later
LOGS_DIR="fix-kowalski-seed-data/logs"
mkdir -p $LOGS_DIR
docker compose -f $COMPOSE_CONFIG logs mongo-init > $LOGS_DIR/mongo-init.log

# Simply wait until mongo-init finishes, then shut down
echo "$(current_datetime) - Waiting for mongo-init to complete"
docker compose -f $COMPOSE_CONFIG wait mongo-init

echo "$(current_datetime) - All tasks completed; shutting down BOOM services"
docker compose -f $COMPOSE_CONFIG down

# Check if any containers exited with a non-zero status, which would indicate an error
EXIT_STATUS=$(docker compose -f $COMPOSE_CONFIG ps -q | xargs docker inspect --format '{{.State.ExitCode}}' | grep -v 0 || true)
if [ -n "$EXIT_STATUS" ]; then
    echo "$(current_datetime) - Error: One or more containers exited with a non-zero status; Please check the logs in $LOGS_DIR for details"
    exit 1
else
    echo "$(current_datetime) - All containers completed successfully; Logs are available in $LOGS_DIR"
fi

exit 0
