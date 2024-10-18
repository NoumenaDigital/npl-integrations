#!/bin/bash

. ./lib/helpers.sh
. ./lib/app_lifecycle.sh
. ./lib/setup_deploy.sh

# TODO separate the script into different functions for each steps, call all steps from a main function
# print a small summary
# separate the application testing into a separate script
# describe what the test is doing, what does it test: the project setup, the deployment, the IAM setup, the integration tests
# add to readme the variables that need to be set in the pipeline
# allow tests in other languages (java, python, kotlin) to be called from here

# run script from the npl-integration repository

set -e

## Creating app

if [ -z "$NC_DOMAIN" ]; then
	echo "NC_DOMAIN not set"
	exit 1
fi
if [ -z "$NC_ORG_NAME" ]; then
	echo "NC_ORG_NAME not set"
	exit 1
fi
if [ -z "$PAAS_ENGINE_VERSION" ]; then
	echo "PAAS_ENGINE_VERSION not set"
	exit 1
fi
if [ -z "$NPL_VERSION" ]; then
	echo "NPL_VERSION not set"
	exit 1
fi

nc_org=$(get_nc_org)
app_name=$(get_nc_app_name)
app_name_clean=$(get_nc_app_name_clean "$app_name")
engine_url=$(get_engine_url "$app_name_clean")
realm_url=$(get_keycloak_url "$app_name_clean")/realms/$app_name_clean

app_id=$(create_app "$nc_org" "$app_name" "$realm_url")
waiting_for_activation "$app_id" "$nc_org"
setup_deploy "$app_id" "$app_name" "$app_name_clean" "$realm_url"
run_services "$app_name_clean"
run_integration_tests "$app_name_clean" "$engine_url" "$realm_url"
kill_services
delete_app "$app_id"
