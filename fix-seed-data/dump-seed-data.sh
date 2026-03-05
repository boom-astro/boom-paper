#!/usr/bin/env bash
# Dump seed data back out using mongodump

set -euo pipefail

DB_NAME="${DB_NAME:?DB_NAME must be set}"

mongodump --uri="mongodb://mongoadmin:mongoadminsecret@mongo:27017/?authSource=admin" \
    --gzip \
    --archive=/data/alerts/boom_throughput.ZTF_alerts_aux.dump.gz \
    --db="$DB_NAME" \
    --collection="ZTF_alerts_aux"
