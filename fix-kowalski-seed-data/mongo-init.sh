#!/usr/bin/env bash
set -e  # Exit on any error

MONGO4_URI="mongodb://mongoadmin:mongoadminsecret@mongo4:27017/$DB_NAME?authSource=admin"

wait_for_mongo4() {
    local max_attempts=60
    local attempt=1
    while [ "$attempt" -le "$max_attempts" ]; do
        if mongosh "$MONGO4_URI" --quiet --eval "db.runCommand({ ping: 1 }).ok" 2>/dev/null | grep -q '^1$'; then
            return 0
        fi
        echo "Mongo4 not reachable yet (attempt $attempt/$max_attempts), retrying..."
        sleep 2
        attempt=$((attempt + 1))
    done
    return 1
}

# Now we load the ZTF_alerts_aux table with the history for all the objects detected on 2025-03-11,
echo "Loading ZTF_alerts_aux collection with data from Mongo 8"
echo "Archive file: /data/alerts/kowalski.ZTF_alerts_aux_mongo8.dump.gz"
ls -lh /data/alerts/kowalski.ZTF_alerts_aux_mongo8.dump.gz || (echo "ERROR: Archive file not found!" && exit 1)

mongorestore --uri="mongodb://mongoadmin:mongoadminsecret@mongo:27017/?authSource=admin" \
    --gzip \
    --archive=/data/alerts/kowalski.ZTF_alerts_aux_mongo8.dump.gz \
    --nsFrom='kowalski_throughput.ZTF_alerts_aux' \
    --nsTo="$DB_NAME.ZTF_alerts_aux"

mongosh "mongodb://mongoadmin:mongoadminsecret@mongo:27017/$DB_NAME?authSource=admin" \
    --eval "db.ZTF_alerts_aux.createIndex({ 'coordinates.radec_geojson': '2dsphere' })"

# verify that we have the expected number of documents in the ZTF_alerts_aux collection
EXPECTED_AUX_ALERTS=27948
ACTUAL_AUX_ALERTS=$(mongosh "mongodb://mongoadmin:mongoadminsecret@mongo:27017/$DB_NAME?authSource=admin" --quiet --eval "db.getSiblingDB('$DB_NAME').ZTF_alerts_aux.countDocuments()")
if [ "$ACTUAL_AUX_ALERTS" -ne "$EXPECTED_AUX_ALERTS" ]; then
    echo "Expected $EXPECTED_AUX_ALERTS documents in ZTF_alerts_aux collection, but found $ACTUAL_AUX_ALERTS"
    exit 1
else
    echo "Successfully loaded ZTF_alerts_aux collection with $ACTUAL_AUX_ALERTS documents"
fi

# Now dump it out the JSON
echo "Exporting ZTF_alerts_aux collection to JSON"
mkdir -p /data/alerts/tmp
mongoexport --uri="mongodb://mongoadmin:mongoadminsecret@mongo:27017/$DB_NAME?authSource=admin" \
    --collection="ZTF_alerts_aux" \
    --out=/data/alerts/tmp/ZTF_alerts_aux.json

# Verify the JSON file was created and has content
if [ ! -f /data/alerts/tmp/ZTF_alerts_aux.json ]; then
    echo "ERROR: JSON export file was not created"
    exit 1
fi
JSON_LINES=$(wc -l < /data/alerts/tmp/ZTF_alerts_aux.json)
echo "JSON export completed: $JSON_LINES lines"

# Now load the JSON into mongo4
echo "Importing ZTF_alerts_aux collection into Mongo 4"
wait_for_mongo4 || (echo "ERROR: mongo4 did not become reachable before import" && exit 1)
IMPORT_COUNT=$(mongoimport --uri="$MONGO4_URI" \
    --collection="ZTF_alerts_aux" \
    --file=/data/alerts/tmp/ZTF_alerts_aux.json 2>&1 | grep -oE "imported [0-9]+" || echo "imported 0")
echo "Import result: $IMPORT_COUNT"

# Now dump out of mongo4
echo "Exporting ZTF_alerts_aux collection from Mongo 4 to BSON archive"
wait_for_mongo4 || (echo "ERROR: mongo4 did not become reachable before dump" && exit 1)
MAX_DUMP_ATTEMPTS=3
DUMP_ATTEMPT=1
while [ "$DUMP_ATTEMPT" -le "$MAX_DUMP_ATTEMPTS" ]; do
    if mongodump --uri="mongodb://mongoadmin:mongoadminsecret@mongo4:27017/?authSource=admin" \
        --gzip \
        --archive=/data/alerts/kowalski.ZTF_alerts_aux.dump.gz \
        --db="$DB_NAME" \
        --collection="ZTF_alerts_aux"; then
        break
    fi
    if [ "$DUMP_ATTEMPT" -eq "$MAX_DUMP_ATTEMPTS" ]; then
        echo "ERROR: mongodump failed after $MAX_DUMP_ATTEMPTS attempts"
        exit 1
    fi
    echo "mongodump failed on attempt $DUMP_ATTEMPT/$MAX_DUMP_ATTEMPTS, retrying after waiting for mongo4..."
    wait_for_mongo4 || (echo "ERROR: mongo4 not reachable after mongodump failure" && exit 1)
    DUMP_ATTEMPT=$((DUMP_ATTEMPT + 1))
done

if [ -f /data/alerts/kowalski.ZTF_alerts_aux.dump.gz ]; then
    echo "Final archive created: $(ls -lh /data/alerts/kowalski.ZTF_alerts_aux.dump.gz | awk '{print $5}')"
else
    echo "ERROR: Final archive was not created"
    exit 1
fi

echo "MongoDB initialization script completed successfully"
exit 0
