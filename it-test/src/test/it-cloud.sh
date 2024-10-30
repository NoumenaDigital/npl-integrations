#!/bin/bash

# script must be run from the npl-integration directory

. ./it-test/src/test/lib/helpers.sh
. ./it-test/src/test/lib/app_lifecycle.sh
. ./it-test/src/test/lib/app_setup_deploy.sh
. ./it-test/src/test/lib/service_lifecycle.sh
. ./it-test/src/test/lib/integration_tests.sh

set -e

if [ -z "$NC_DOMAIN" ]; then
	echo "NC_DOMAIN not set"
	exit 1
fi
if [ -z "$NC_ORG_NAME" ]; then
	echo "NC_ORG_NAME not set"
	exit 1
fi
if [ -z "$NC_ENGINE_VERSION" ]; then
	echo "NC_ENGINE_VERSION not set"
	exit 1
fi
if [ -z "$NC_ENV" ]; then
	echo "NC_ENV not set"
	exit 1
fi
if [ -z "$NPL_VERSION" ]; then
	echo "NPL_VERSION not set"
	exit 1
fi

echo "Performing integration tests on domain '$NC_DOMAIN' for org '$NC_ORG_NAME' with engine version '$NC_ENGINE_VERSION' with auth '$NC_ENV' and NPL version '$NPL_VERSION'"

org_id=$(get_nc_org)
if [ -z "$org_id" ]; then
	echo "NC org id not found for NC_ORG_NAME '$NC_ORG_NAME' on domain '$NC_DOMAIN'"
	exit 1
fi

app_name=$(get_nc_app_name)
app_name_clean=$(get_nc_app_name_clean "$app_name")
engine_url=$(get_engine_url "$app_name_clean")
realm_url="$(get_keycloak_url "$app_name_clean")/realms/$app_name_clean"

app_id=$(create_app "$org_id" "$app_name" "$realm_url")
echo "App ID: $app_id"
waiting_for_activation "$app_id" "$org_id"
setup_deploy "$app_id" "$app_name" "$app_name_clean" "$realm_url"
run_services "$app_name_clean"
listener_pid=$!
echo "Listener service PID: $listener_pid"
sleep 3
run_integration_tests "$app_name_clean" "$engine_url" "$realm_url"
kill_services "$listener_pid"
delete_app "$app_id"
