#!/bin/bash

# script must be run from the npl-integration directory

. ./it-test/src/test/lib/integration_tests.sh

set -e

if [ -f .env ]; then
  echo "Loading environment variables from .env"
  export $(cat .env | xargs)
fi

app_slug="$VITE_NC_APP_SLUG"
engine_url=http://localhost:12000
realm_url="http://localhost:11000/realms/$VITE_NC_APP_SLUG"

run_integration_tests "$app_slug" "$engine_url" "$realm_url"
