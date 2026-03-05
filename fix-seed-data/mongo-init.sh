#!/usr/bin/env bash

# Now we load the ZTF_alerts_aux table with the history for all the objects detected on 2025-03-11,
echo "Loading ZTF_alerts_aux collection with data from boom_throughput.ZTF_alerts_aux_before_fix.dump.gz"
mongorestore --uri="mongodb://mongoadmin:mongoadminsecret@mongo:27017/?authSource=admin" \
    --gzip \
    --archive=/boom_throughput.ZTF_alerts_aux_before_fix.dump.gz \
    --nsInclude='boom_throughput.ZTF_alerts_aux' \
    --nsFrom='boom_throughput.ZTF_alerts_aux' \
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

echo "MongoDB initialization script completed successfully"
exit 0
