"""Script to benchmark Kowalski."""

import argparse
import json
import os
import shutil
import subprocess

import yaml

# First, create the config
parser = argparse.ArgumentParser(description="Benchmark Kowalski")
parser.add_argument(
    "--n-workers",
    type=int,
    default=6,
    help="Number of workers to use for benchmarking.",
)
args = parser.parse_args()
with open("config/kowalski/config-template.yaml", "r") as f:
    config = yaml.safe_load(f)
config["kowalski"]["dask"]["n_workers"] = args.n_workers
with open("config/kowalski/config.yaml", "w") as f:
    yaml.safe_dump(config, f, default_flow_style=False)

# Reformat filter for insertion into database
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

# Delete existing logs if they exist
logs_dir = "logs/kowalski"
if os.path.exists(logs_dir):
    shutil.rmtree(logs_dir)

# Now run the benchmark shell script
subprocess.run(["bash", "scripts/benchmark-kowalski.sh"], check=True)

# Rename the logs directory
shutil.move("logs/kowalski", f"logs/kowalski-n={args.n_workers}")
