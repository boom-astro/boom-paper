#!/usr/bin/env bash

set -euo pipefail

COMPOSE_CONFIG="config/kowalski/compose.yaml"
BG_PIDS=()

# A function that returns the current date and time
current_datetime() {
    TZ=utc date "+%Y-%m-%d %H:%M:%S"
}

cleanup() {
    echo "$(current_datetime) - Cleaning up background processes and services"
    if [ ${#BG_PIDS[@]} -gt 0 ]; then
        kill "${BG_PIDS[@]}" 2>/dev/null || true
        wait "${BG_PIDS[@]}" 2>/dev/null || true
    fi
    docker compose -f "$COMPOSE_CONFIG" down || true
}

trap cleanup EXIT INT TERM

# Create some files that must exist for Kowalski to work
echo benchmarking > kowalski/version.txt
echo thisisarandomkeyfortesting > kowalski/mongo_key.yaml

# Remove any existing containers
docker compose -f "$COMPOSE_CONFIG" down
docker compose -f config/boom/compose.yaml down

# Spin up services with Docker Compose
mkdir -p logs/kowalski
rm -rf logs/kowalski/*
docker compose -f "$COMPOSE_CONFIG" up --build -d

# Send the logs to file so we can analyze later
docker compose -f "$COMPOSE_CONFIG" logs -f producer > logs/kowalski/producer.log &
BG_PIDS+=($!)
docker compose -f "$COMPOSE_CONFIG" logs -f mongo-init > logs/kowalski/mongo-init.log &
BG_PIDS+=($!)

# Detect that all alerts have been processed
# First wait for the file to be created
echo "$(current_datetime) - Waiting for Dask cluster log file to be created"
while [ ! -f logs/kowalski/dask_cluster.log ]; do
    sleep 1
done

# Send ingester container stats to log file
docker compose -f "$COMPOSE_CONFIG" stats ingester --format json \
    > logs/kowalski/ingester.stats.log &
BG_PIDS+=($!)

# Look for classifications, since log lines can be unreliable with Dask
echo "$(current_datetime) - Waiting for all alerts to be ingested and classified"
EXPECTED_ALERTS=29142
while [ $(docker compose -f "$COMPOSE_CONFIG" exec mongo mongo "mongodb://mongoadmin:mongoadminsecret@localhost:27017" --quiet --eval "db.getSiblingDB('kowalski').ZTF_alerts.countDocuments({ classifications: { \$exists: true } })") -lt $EXPECTED_ALERTS ]; do
    sleep 1
done

echo "$(current_datetime) - All alerts ingested and classified"

# Export collection stats to JSON before shutting down
echo "$(current_datetime) - Collecting MongoDB collection stats"
MONGO_RESULT="$({
	docker compose -f "$COMPOSE_CONFIG" exec mongo \
		mongo -u mongoadmin -p mongoadminsecret --authenticationDatabase admin \
		--quiet \
		--eval '
const dbName = "kowalski";
const d = db.getSiblingDB(dbName);
function collectionStats(name) {
	const c = d.getCollection(name);
	const s = c.stats();
	return {
		collection: name,
		count: c.count(),
		data_size_bytes: s.size,
		storage_size_bytes: s.storageSize,
		total_index_size_bytes: s.totalIndexSize,
		total_size_bytes: s.totalSize
	};
}
const collectionNames = d.getCollectionNames().sort();
const out = {
	generated_at_utc: new Date().toISOString(),
	database: dbName,
	collections: collectionNames.map(collectionStats)
};
print(JSON.stringify(out));
'
} | tail -n 1)"

if [ -n "$MONGO_RESULT" ]; then
	if command -v jq >/dev/null 2>&1; then
		printf '%s\n' "$MONGO_RESULT" | jq . > logs/kowalski/collection_stats.json
	else
		printf '%s\n' "$MONGO_RESULT" > logs/kowalski/collection_stats.json
	fi
	echo "$(current_datetime) - Wrote collection stats to logs/kowalski/collection_stats.json"
fi

echo "$(current_datetime) - All tasks completed; shutting down Kowalski services"

# Shut down the services
docker compose -f "$COMPOSE_CONFIG" down

exit 0
