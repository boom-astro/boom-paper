#!/usr/bin/env bash

COMPOSE_CONFIG="config/kowalski/compose.yaml"

# A function that returns the current date and time
current_datetime() {
    TZ=utc date "+%Y-%m-%d %H:%M:%S"
}

# A function to check that a number is a valid integer
is_integer() {
    [[ "$1" =~ ^-?[0-9]+$ ]]
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
echo "$(current_datetime) - Waiting for Dask cluster log file to be created"
while [ ! -f logs/kowalski/dask_cluster.log ]; do
    sleep 1
done

# Send ingester container stats to log file
docker compose -f $COMPOSE_CONFIG stats ingester --format json \
    > logs/kowalski/ingester.stats.log &

# Look for classifications, since log lines can be unreliable with Dask
echo "$(current_datetime) - Waiting for all alerts to be ingested and classified"
EXPECTED_ALERTS=29142
while true; do
    COUNT=$(docker compose -f $COMPOSE_CONFIG exec mongo mongosh "mongodb://mongoadmin:mongoadminsecret@localhost:27017" --quiet --eval "db.getSiblingDB('kowalski').ZTF_alerts.countDocuments({ classifications: { \$exists: true } })")
    #$ use the is_integer function to check if COUNT is a valid integer
    if is_integer "$COUNT" && [ "$COUNT" -ge "$EXPECTED_ALERTS" ]; then
        break
    fi
    sleep 1
done

echo "$(current_datetime) - All tasks completed; shutting down Kowalski services"

# Shut down the services
docker compose -f $COMPOSE_CONFIG down

exit 0
