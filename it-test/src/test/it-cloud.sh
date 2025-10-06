#!/bin/bash

# script must be run from the npl-integration directory

. ./it-test/src/test/lib/helpers.sh
. ./it-test/src/test/lib/app_lifecycle.sh
. ./it-test/src/test/lib/app_setup_deploy.sh
. ./it-test/src/test/lib/service_lifecycle.sh
. ./it-test/src/test/lib/integration_tests.sh

set -e

if [ -f .env ]; then
  echo "Loading environment variables from .env"
  export $(cat .env | xargs)
fi

if [ -z "$NC_DOMAIN" ]; then
	echo "NC_DOMAIN not set"
	exit 1
fi
if [ -z "$VITE_NC_TENANT_SLUG" ]; then
	echo "VITE_NC_TENANT_SLUG not set"
	exit 1
fi
if [ -z "$VITE_NC_APP_SLUG" ]; then
	echo "VITE_NC_APP_SLUG not set"
	exit 1
fi

echo "Performing integration tests on domain '$NC_DOMAIN' for org '$VITE_NC_TENANT_SLUG' and app '$VITE_NC_APP_SLUG'"

org_slug=$VITE_NC_TENANT_SLUG
app_slug=$VITE_NC_APP_SLUG

engine_url=$(get_engine_url "$org_slug" "$app_slug")
realm_url="$(get_keycloak_url "$org_slug" "$app_slug")/realms/$app_slug"

# waiting_for_activation "$app_slug" "$org_slug" TODO - re-enable when we can get the app status
setup_deploy "$app_slug" "$app_name" "$app_slug" "$realm_url"
run_services "$app_slug"
listener_pid=$!
echo "Listener service PID: $listener_pid"
sleep 3
run_integration_tests "$app_slug" "$engine_url" "$realm_url"
kill_services "$listener_pid"
