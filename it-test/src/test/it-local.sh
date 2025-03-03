#!/bin/bash

# script must be run from the npl-integration directory

. ./it-test/src/test/lib/integration_tests.sh

set -e

if [ -f .env ]; then
  echo "Loading environment variables from .env"
  export $(cat .env | xargs)
fi

app_name_clean="$VITE_NC_APP_NAME"
engine_url=http://localhost:12000
realm_url="http://localhost:11000/realms/$VITE_NC_APP_NAME"

run_integration_tests "$app_name_clean" "$engine_url" "$realm_url"
