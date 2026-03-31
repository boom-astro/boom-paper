#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_FILE="${ROOT_DIR}/config/kowalski/compose.yaml"
OUTPUT_FILE="${ROOT_DIR}/results/kowalski-db-sizes.json"
TMP_RUN_DIR=""

N_WORKERS=7
EXPECTED_ALERTS=29142

if ! command -v python >/dev/null 2>&1; then
	echo "Error: python not found in PATH (expected from the 'run' environment)"
	exit 1
fi

compose() {
	docker compose -f "$COMPOSE_FILE" "$@"
}

cleanup() {
	compose down >/dev/null 2>&1 || true
	if [ -n "$TMP_RUN_DIR" ] && [ -d "$TMP_RUN_DIR" ]; then
		rm -rf "$TMP_RUN_DIR" >/dev/null 2>&1 || true
	fi
}
trap cleanup EXIT INT TERM

mkdir -p "$(dirname "$OUTPUT_FILE")"

# Run from a temporary workspace so compose ${PWD}/logs mounts do not touch
# repository benchmark logs.
TMP_RUN_DIR="$(mktemp -d)"
ln -s "$ROOT_DIR/boom-producer" "$TMP_RUN_DIR/boom-producer"
ln -s "$ROOT_DIR/config" "$TMP_RUN_DIR/config"
ln -s "$ROOT_DIR/data" "$TMP_RUN_DIR/data"
ln -s "$ROOT_DIR/kowalski" "$TMP_RUN_DIR/kowalski"
ln -s "$ROOT_DIR/scripts" "$TMP_RUN_DIR/scripts"
mkdir -p "$TMP_RUN_DIR/logs"
cd "$TMP_RUN_DIR"

# Prepare Kowalski config and filter payload.
python - <<'PY'
import json
import yaml

n_workers = 7

with open("config/kowalski/config-template.yaml", "r") as f:
    config = yaml.safe_load(f)
config["kowalski"]["dask"]["n_workers"] = n_workers
with open("config/kowalski/config.yaml", "w") as f:
    yaml.safe_dump(config, f, default_flow_style=False)

with open("config/kowalski/cats150.kowalski.json", "r") as f:
    cats150 = json.load(f)

for_insert = {
    "filter_id": 1,
    "group_id": 41,
    "catalog": "ZTF_alerts",
    "permissions": [1, 2, 3],
    "active": True,
    "autosave": False,
    "auto_followup": {},
    "update_annotations": False,
    "active_fid": "first",
    "fv": [
        {
            "fid": "first",
            "created_at": "2021-01-01T00:00:00",
            "pipeline": json.dumps(cats150),
        }
    ],
}

with open("config/kowalski/cats150.json", "w") as f:
    json.dump(for_insert, f)
PY

# Files required by Kowalski startup.
echo benchmarking > "kowalski/version.txt"
echo thisisarandomkeyfortesting > "kowalski/mongo_key.yaml"

# Ensure clean startup.
compose down

docker compose -f "${ROOT_DIR}/config/boom/compose.yaml" down

mkdir -p "logs/kowalski-db-sizes"
rm -rf "logs/kowalski-db-sizes"/*

compose up --build -d

# Wait until all expected alerts have classifications.
echo "Waiting for Kowalski to classify all alerts"
while true; do
	count="$(compose exec -T mongo \
		mongo -u mongoadmin -p mongoadminsecret --authenticationDatabase admin \
		--quiet --eval "db.getSiblingDB('kowalski').ZTF_alerts.count({ classifications: { \\\$exists: true } })" | tail -n 1 | tr -d '\\r')"
	if [ "${count:-0}" -ge "$EXPECTED_ALERTS" ]; then
		break
	fi
	sleep 1
done

echo "Collecting MongoDB collection stats"
MONGO_RESULT="$({
	compose exec -T mongo \
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
const out = {
	generated_at_utc: new Date().toISOString(),
	database: dbName,
	benchmark_config: {
		n_workers: 7,
		expected_alerts: 29142
	},
	collections: [
		collectionStats("ZTF_alerts"),
		collectionStats("ZTF_alerts_aux")
	]
};
print(JSON.stringify(out));
'
} | tail -n 1)"

if command -v jq >/dev/null 2>&1; then
	printf '%s\n' "$MONGO_RESULT" | jq . > "$OUTPUT_FILE"
else
	printf '%s\n' "$MONGO_RESULT" > "$OUTPUT_FILE"
fi

echo "Wrote database size report to: $OUTPUT_FILE"

echo "Bringing containers down"
trap - EXIT
cleanup
