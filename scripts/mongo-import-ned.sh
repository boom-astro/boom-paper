#!/usr/bin/env bash

# Only import NED alerts if the collection does not exist
NED_COLLECTION_EXISTS=$(mongosh "mongodb://mongoadmin:mongoadminsecret@mongo:27017/$DB_NAME?authSource=admin" --quiet --eval "db.getCollectionNames().includes('NED_alerts')")
echo "NED collection exists: $NED_COLLECTION_EXISTS"

if [ "$NED_COLLECTION_EXISTS" = "false" ]; then
    echo "Importing NED alerts into $DB_NAME MongoDB database"
    gunzip -kc /kowalski.NED.json.gz | \
        mongoimport \
        "mongodb://mongoadmin:mongoadminsecret@mongo:27017/$DB_NAME?authSource=admin$DB_ADD_URI" \
        --collection NED_alerts \
        --jsonArray \
        --drop
else
    echo "NED alerts already imported; skipping import"
fi

# Always drop ZTF catalogs, ZTF_alerts, ZTF_alerts_aux, ZTF_alerts_cutouts
mongosh "mongodb://mongoadmin:mongoadminsecret@mongo:27017/$DB_NAME?authSource=admin" --quiet --eval "
    db.ZTF_alerts.drop();
    db.ZTF_alerts_aux.drop();
    db.ZTF_alerts_cutouts.drop();"

# Create a 2d index on coordinates.radec_geojson
echo "Creating 2d index on coordinates.radec_geojson"
mongosh "mongodb://mongoadmin:mongoadminsecret@mongo:27017/$DB_NAME?authSource=admin" \
    --eval "db.NED.createIndex({ 'coordinates.radec_geojson': '2dsphere' })"
