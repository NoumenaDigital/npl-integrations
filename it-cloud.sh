#!/bin/bash

get_paas_engine_version() {
    echo "2024.1.8"
}

get_npl_version() {
    echo "1.0"
}

get_nc_domain() {
    echo "noumena.cloud"
}

get_nc_app_name() {
    echo "it$(date +%y%m%d_%H%M%S)"
}

get_nc_org_name() {
    echo "training"
}

get_nc_app_name_clean() {
    local app_name=$1
    echo $app_name | tr -d '-' | tr -d '_'
}

get_nc_org() {
    echo "$(./cli org list 2>/dev/null | jq --arg NC_ORG_NAME "$(get_nc_org_name)" -r '.[] | select(.slug == $NC_ORG_NAME) | .id' 2>/dev/null)"
}

get_nc_app() {
    local app_name=$1
    echo "$(./cli app list -org $(get_nc_org) 2>/dev/null | jq --arg NC_APP_NAME "$app_name" '.[] | select(.name == $NC_APP_NAME) | .id' 2>/dev/null)"
}

get_nc_keycloak_username() {
    local app_name=$1
    echo "$(./cli app secrets -app $(get_nc_app $app_name) 2>/dev/null | jq -r '.iam_username' 2>/dev/null)"
}

get_nc_keycloak_password() {
    local app_name=$1
    echo "$(./cli app secrets -app $(get_nc_app $app_name) 2>/dev/null | jq -r '.iam_password' 2>/dev/null)"
}

get_keycloak_url() {
    local app_name=$1
    echo "https://keycloak-$(get_nc_org_name)-$(get_nc_app_name_clean $app_name).$(get_nc_domain)"
}

get_engine_url() {
    local app_name=$1
    echo "https://engine-$(get_nc_org_name)-$app_name.$(get_nc_domain)"
}

get_read_model_url() {
    echo "https://engine-$(get_nc_org_name)-$app_name.$(get_nc_domain)/graphql"
}

zip() {
    mkdir -p target
    cd target && \
    cp -r ../npl/src/main/npl-* . && cp -r ../npl/src/main/yaml . && cp -r ../npl/src/main/kotlin-script . && \
    zip -r npl-integrations-$(NPL_VERSION).zip *
}

app_name=$(get_nc_app_name)
app_name_clean=$(get_nc_app_name_clean $app_name)
echo "Creating app $app_name"
realm_url=$(get_keycloak_url $app_name)/realms/$app_name_clean
result=$(./cli app create -org $(get_nc_org) -engine $(get_paas_engine_version) -name $app_name -provider MicrosoftAzure -trusted_issuers '["$realm_url"]')
app_id=$(echo "$result" | jq -r '.id')
echo "App created with ID $app_id"

get_app_details() {
    local app_id=$1
    ./cli app detail -org $(get_nc_org) -app $app_id
}

check_app_status() {
    local app_id=$1
    get_app_details $app_id | jq -r '.state'
}

sleep_amount=20
check_interval=10
sleep $sleep_amount

# Initialize the status
status=$(check_app_status $app_id)

while [ "$status" != "active" ]; do
    echo "App status: $status. Waiting for $check_interval seconds"
    sleep $check_interval
    sleep_amount=$((sleep_amount + $check_interval))
    status=$(check_app_status $app_id)
done

echo "App active in less than $sleep_amount seconds."

zip

./cli app deploy -app $app_id -binary ./target/npl-integrations-$(get_npl_version).zip

access_token=$(curl -s '$realm_url/protocol/openid-connect/token' \
		 -H 'Content-Type: application/x-www-form-urlencoded' \
		 -d 'username=cherry' \
     -d 'password=cherry-on-the-cake' \
		 -d 'grant_type=password' \
		 -d 'client_id=library' | jq -r .access_token)

iou_id=$(./bash/client.sh --host https://engine-library.shared-dev.noumenadigital.com createIou Authorization:"Bearer ${access_token}" \
		description=="IOU from integration-test on $(shell date +%d.%m.%y) at $(shell date +%H:%M:%S)" \
		forAmount:=100 \
		@parties:='{"issuer":{"entity":{"email":["alice@noumenadigital.com"]},"access":{}},"payee":{"entity":{"email":["bob@noumenadigital.com"]},"access":{}}}' | jq -r '.["@id"]')

./bash/client.sh --host https://engine-library.shared-dev.noumenadigital.com iouPay id="$iou_id" Authorization:"Bearer $access_token" amount:=10 | jq -r '.["@id"]'; \

sleep 10

iou_state=$( ./bash/client.sh --host localhost:12000 getIouByID id="$iou_id" Authorization:"Bearer $access_token" | jq -r '.["@state"]');
if [[ iou_state = "payment_confirmation_required" ]]; then
    echo "IOU not reset to unpaid"
    exit 1
fi

## bash: run python service
## bring everything down

./cli app delete -app $app_id
