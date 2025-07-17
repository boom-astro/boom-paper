#!/usr/bin/env bash

echo "Importing NED alerts into $DB_NAME MongoDB database"

gunzip -kc /kowalski.NED.json.gz | \
    mongoimport \
    "mongodb://mongoadmin:mongoadminsecret@mongo:27017/$DB_NAME?authSource=admin$DB_ADD_URI" \
    --collection NED \
    --jsonArray \
    --drop

# then, create a 2d index on coordinates.radec_geojson
echo "Creating 2d index on coordinates.radec_geojson"
mongosh "mongodb://mongoadmin:mongoadminsecret@mongo:27017/$DB_NAME?authSource=admin" \
    --eval "db.NED.createIndex({ 'coordinates.radec_geojson': '2dsphere' })"
