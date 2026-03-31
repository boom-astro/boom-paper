#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BOOM_REPO_DIR="${ROOT_DIR}/boom"
RUN_SCRIPT="${BOOM_REPO_DIR}/tests/throughput/run.py"
COMPOSE_FILE="${BOOM_REPO_DIR}/tests/throughput/compose.yaml"

# compose.yaml requires BOOM_REPO_ROOT for variable interpolation.
export BOOM_REPO_ROOT="$BOOM_REPO_DIR"

N_ALERT_WORKERS=3
N_ENRICHMENT_WORKERS=6
N_FILTER_WORKERS=3
TIMEOUT_SECS=300
OUTPUT_FILE="${ROOT_DIR}/results/boom-db-sizes.json"
TMP_RUN_DIR=""

if [ ! -f "$RUN_SCRIPT" ]; then
	echo "Error: could not find benchmark runner at $RUN_SCRIPT"
	exit 1
fi

if [ ! -f "$COMPOSE_FILE" ]; then
	echo "Error: could not find compose file at $COMPOSE_FILE"
	exit 1
fi

if ! command -v python >/dev/null 2>&1; then
	echo "Error: python not found in PATH (expected from the 'run' environment)"
	exit 1
fi

# Ensure ${PWD} references in compose.yaml resolve to repo-local data paths.
cd "$ROOT_DIR"

compose() {
	BOOM_REPO_ROOT="$BOOM_REPO_DIR" docker compose -f "$COMPOSE_FILE" "$@"
}

cleanup() {
	compose down >/dev/null 2>&1 || true
	if [ -n "$TMP_RUN_DIR" ] && [ -d "$TMP_RUN_DIR" ]; then
		rm -rf "$TMP_RUN_DIR"
	fi
}
trap cleanup EXIT INT TERM

mkdir -p "$(dirname "$OUTPUT_FILE")"

echo "Running BOOM throughput benchmark with keep-up enabled for stats collection"
TMP_RUN_DIR="$(mktemp -d)"
ln -s "$ROOT_DIR/data" "$TMP_RUN_DIR/data"
(
	cd "$TMP_RUN_DIR"
	python "$RUN_SCRIPT" \
		--boom-repo-dir "$BOOM_REPO_DIR" \
		--n-alert-workers "$N_ALERT_WORKERS" \
		--n-enrichment-workers "$N_ENRICHMENT_WORKERS" \
		--n-filter-workers "$N_FILTER_WORKERS" \
		--timeout "$TIMEOUT_SECS" \
		--keep-up
)

echo "Collecting MongoDB collection stats"
MONGO_RESULT="$({
	compose exec -T mongo \
		mongosh "mongodb://mongoadmin:mongoadminsecret@localhost:27017/admin?authSource=admin" \
		--quiet \
		--eval '
const dbName = "boom-benchmarking";
const d = db.getSiblingDB(dbName);
function collectionStats(name) {
	const c = d.getCollection(name);
	const s = c.stats();
  return {
	collection: name,
	count: c.countDocuments(),
	data_size_bytes: s.size,
	storage_size_bytes: s.storageSize,
	total_index_size_bytes: s.totalIndexSize,
	total_size_bytes: s.totalSize
  };
}
const collectionNames = d
	.getCollectionInfos({ type: "collection" })
	.map((info) => info.name)
	.sort();
const out = {
  generated_at_utc: new Date().toISOString(),
  database: dbName,
  benchmark_config: {
	n_alert_workers: Number("'"$N_ALERT_WORKERS"'"),
	n_enrichment_workers: Number("'"$N_ENRICHMENT_WORKERS"'"),
	n_filter_workers: Number("'"$N_FILTER_WORKERS"'"),
	timeout_secs: Number("'"$TIMEOUT_SECS"'")
  },
  collections: collectionNames.map(collectionStats)
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
