#!/bin/bash

# script must be run from the npl-integration directory

. ./it-test/src/test/lib/integration_tests.sh

set -e

app_name_clean="nplintegrations"
engine_url=http://localhost:12000
realm_url=http://localhost:11000/realms/nplintegrations

run_integration_tests "$app_name_clean" "$engine_url" "$realm_url"
