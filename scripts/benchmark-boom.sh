#!/usr/bin/env bash

# Spin up BOOM services with Docker Compose
docker compose -f config/boom/compose.yaml up -d

# Run Kakfa producer in the boom environment
calkit xenv -n boom -- /app/kafka_producer ztf 20250614 public

# Now time how long it takes for all of the alerts to be sent to the output
# TODO: Send the logs somewhere so we can analyze later?

# Shut down the BOOM services
docker compose -f config/boom/compose.yaml down
