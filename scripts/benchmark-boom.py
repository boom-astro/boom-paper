"""Script to benchmark BOOM."""

import argparse
import os
import subprocess

import yaml

# First, create the config
parser = argparse.ArgumentParser(description="Benchmark BOOM")
parser.add_argument(
    "--n-alert-workers",
    type=int,
    default=3,
    help="Number of alert workers to use for benchmarking.",
)
parser.add_argument(
    "--n-ml-workers",
    type=int,
    default=3,
    help="Number of machine learning workers to use for benchmarking.",
)
parser.add_argument(
    "--n-filter-workers",
    type=int,
    default=3,
    help="Number of filter workers to use for benchmarking.",
)
args = parser.parse_args()
with open("config/boom/config-template.yaml", "r") as f:
    config = yaml.safe_load(f)
config["workers"]["ZTF"]["alert"]["n_workers"] = args.n_alert_workers
config["workers"]["ZTF"]["ml"]["n_workers"] = args.n_ml_workers
config["workers"]["ZTF"]["filter"]["n_workers"] = args.n_filter_workers
with open("config/boom/config.yaml", "w") as f:
    yaml.safe_dump(config, f, default_flow_style=False)

logs_dir = os.path.join(
    "logs",
    "boom-"
    + (
        f"na={args.n_alert_workers}-"
        f"nml={args.n_ml_workers}-"
        f"nf={args.n_filter_workers}"
    ),
)

# Now run the benchmark
subprocess.run(["bash", "scripts/benchmark-boom.sh", logs_dir], check=True)
