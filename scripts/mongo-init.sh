#!/usr/bin/env bash

# The NED collection name is just 'NED' for BOOM, but 'NED_BetaV3' for Kowalski
if [ $DB_NAME = "kowalski" ]; then
    NED_COLLECTION_NAME="NED_BetaV3"
else
    NED_COLLECTION_NAME="NED"
fi

# Only import NED alerts if the collection does not exist
NED_COLLECTION_EXISTS=$(mongosh "mongodb://mongoadmin:mongoadminsecret@mongo:27017/$DB_NAME?authSource=admin" --quiet --eval "db.getCollectionNames().includes('$NED_COLLECTION_NAME')")
echo "NED collection exists: $NED_COLLECTION_EXISTS"

if [ "$NED_COLLECTION_EXISTS" = "false" ]; then
    echo "Importing NED alerts into $DB_NAME MongoDB database"
    gunzip -kc /kowalski.NED.json.gz | \
        mongoimport \
        "mongodb://mongoadmin:mongoadminsecret@mongo:27017/$DB_NAME?authSource=admin$DB_ADD_URI" \
        --collection $NED_COLLECTION_NAME \
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
    --eval "db.$NED_COLLECTION_NAME.createIndex({ 'coordinates.radec_geojson': '2dsphere' })"

# Insert a cats150 filter into filters collection
echo "Inserting cats150 filter into filters collection"
mongoimport \
    "mongodb://mongoadmin:mongoadminsecret@mongo:27017/$DB_NAME?authSource=admin$DB_ADD_URI" \
    --collection filters \
    --file /cats150.json \
    --drop
