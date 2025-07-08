#!/usr/bin/env bash

echo "Importing NED alerts into $DB_NAME MongoDB database"

gunzip -kc /kowalski.NED.json.gz | \
    mongoimport \
    "mongodb://mongoadmin:mongoadminsecret@mongo:27017/$DB_NAME?authSource=admin$DB_ADD_URI" \
    --collection NED_alerts \
    --jsonArray \
    --drop
