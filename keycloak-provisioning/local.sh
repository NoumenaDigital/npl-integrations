#!/bin/sh

set -o errexit
set -o nounset
set -e

export KEYCLOAK_USER=${KEYCLOAK_USER?: "KEYCLOAK_USER has not been set" }
export KEYCLOAK_PASSWORD=${KEYCLOAK_PASSWORD?: "KEYCLOAK_PASSWORD has not been set" }
export KEYCLOAK_URL=${KEYCLOAK_URL?: "KEYCLOAK_URL has not been set" }
export TF_VAR_default_password=${TF_VAR_default_password?: "TF_VAR_default_password has not been set"}
export TF_VAR_app_name=${TF_VAR_app_name?: "TF_VAR_app_name has not been set"}

terraform apply -auto-approve -state=state.tfstate
