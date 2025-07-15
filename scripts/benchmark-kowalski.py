"""Script to benchmark Kowalski."""

import argparse
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

# Delete existing logs if they exist
logs_dir = "logs/kowalski"
if os.path.exists(logs_dir):
    shutil.rmtree(logs_dir)

# Now run the benchmark shell script
subprocess.run(["bash", "scripts/benchmark-kowalski.sh"], check=True)

# Rename the logs directory
shutil.move("logs/kowalski", f"logs/kowalski-n={args.n_workers}")
