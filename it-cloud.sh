#!/bin/bash

set -e

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
	echo "$(./cli org list | jq --arg NC_ORG_NAME "$(get_nc_org_name)" -r '.[] | select(.slug == $NC_ORG_NAME) | .id')"
}

get_nc_keycloak_username() {
	local app_id=$1
	echo "$(./cli app secrets -app $app_id | jq -r '.iam_username')"
}

get_nc_keycloak_password() {
	local app_id=$1
	echo "$(./cli app secrets -app $app_id | jq -r '.iam_password')"
}

get_keycloak_url() {
	local app_name=$1
	echo "https://keycloak-$(get_nc_org_name)-$(get_nc_app_name_clean $app_name).$(get_nc_domain)"
}

get_engine_url() {
	local app_name=$1
	echo "https://engine-$(get_nc_org_name)-$(get_nc_app_name_clean $app_name).$(get_nc_domain)"
}

get_read_model_url() {
	echo "https://engine-$(get_nc_org_name)-$(get_nc_app_name_clean $app_name).$(get_nc_domain)/graphql"
}

make_zip() {
	mkdir -p target
	mkdir -p target/src
	cp -R npl/src/main/npl-$(get_npl_version) target/src/
	cp -R npl/src/main/yaml target/src/
	cp -R npl/src/main/kotlin-script target/src/
	cd target/src
	zip -r ../npl-integrations-$(get_npl_version).zip *
	cd ../..
}

populate_iam() {
	local app_name=$1
	local app_id=$2
	local my_realm_url=$3

	echo "Populating IAM for app $app_name with realm $my_realm_url"

	local keycloak_user=$(get_nc_keycloak_username $app_id)
	local keycloak_password=$(get_nc_keycloak_password $app_id)
	local keycloak_url=$(get_keycloak_url $app_name)

	echo "fetching admin token: $keycloak_url/realms/master/protocol/openid-connect/token"
	local keycloak_login=$(curl --location --request POST --header 'Content-Type: application/x-www-form-urlencoded' \
		--data-urlencode "username=$keycloak_user" \
		--data-urlencode "password=$keycloak_password" \
		--data-urlencode "client_id=admin-cli" \
		--data-urlencode "grant_type=password" \
		"$keycloak_url/realms/master/protocol/openid-connect/token")
	echo "keycloak_login: $keycloak_login"
	local admin_token=$(echo $keycloak_login | jq -r '.access_token')
	curl --location --request DELETE "$keycloak_url/admin/realms/$(get_nc_app_name_clean $app_name)" \
		--header "Content-Type: application/x-www-form-urlencoded" \
		--header "Authorization: Bearer $admin_token"

	cd keycloak-provisioning
	terraform init

	KEYCLOAK_USER=$keycloak_user \
	KEYCLOAK_PASSWORD=$keycloak_password \
	KEYCLOAK_URL=$keycloak_url \
	TF_VAR_default_password=welcome \
	TF_VAR_systemuser_secret=super-secret-system-security-safe \
	TF_VAR_app_name=$app_name_clean \
	./local.sh

	cd ..
}

get_app_details() {
	local app_id=$1
	./cli app detail -org $(get_nc_org) -app $app_id
}

check_app_status() {
	local app_id=$1
	get_app_details $app_id | jq -r '.state'
}

## Creating app
# app_name=it241014_083552
app_name=$(get_nc_app_name)
app_name_clean=$(get_nc_app_name_clean $app_name)
echo "Creating app $app_name"
realm_url=$(get_keycloak_url $app_name)/realms/$app_name_clean
result=$(./cli app create -org $(get_nc_org) -engine $(get_paas_engine_version) -name $app_name -provider MicrosoftAzure -trusted_issuers "[\"$realm_url\"]")
# app_id=d1a18aa9-17de-4d8e-ad6c-11d536762cd4
app_id=$(echo "$result" | jq -r '.id')
echo "App created with ID $app_id"

## Waiting for app to be active
sleep_amount=0
check_interval=10
sleep $sleep_amount

status=$(check_app_status $app_id)

if [ -z "$status" ]; then
	echo "App not found"
	exit 1
fi

while [ "$status" != "active" ]; do
	echo "App status: $status. Waiting for $check_interval seconds"
	sleep $check_interval
	sleep_amount=$((sleep_amount + $check_interval))
	status=$(check_app_status $app_id)
done

echo "App active in less than $sleep_amount seconds."

## Deploying app & configuring IAM

make_zip

./cli app deploy -app $app_id -binary ./target/npl-integrations-$(get_npl_version).zip

populate_iam $app_name $app_id $realm_url

## Running python listener
source venv/bin/activate
REALM="$app_name_clean" python python-listener/app.py &

## Running integration tests
access_token=$(curl -s "$realm_url/protocol/openid-connect/token" \
	-H 'Content-Type: application/x-www-form-urlencoded' \
	-d 'username=alice' \
	-d 'password=alice' \
	-d 'grant_type=password' \
	-d "client_id=$app_name_clean" | jq -r '.access_token')

if [ -z "$access_token" ]; then
	echo "Access token not found"
	exit 1
fi

iou_id=$(./bash/client.sh --host $(get_engine_url $app_name) createIou Authorization:"Bearer $access_token" \
	description=="IOU from integration-test on $(date +%d.%m.%y_%H:%M:%S)" \
	forAmount:=100 \
	@parties:='{"issuer":{"entity":{"email":["alice@noumenadigital.com"]},"access":{}},"payee":{"entity":{"email":["bob@noumenadigital.com"]},"access":{}}}' | jq -r '.["@id"]')

if [ -z "$iou_id" ]; then
	echo "Iou not created"
	exit 1
else
	echo "IOU created with ID $iou_id"
fi

./bash/client.sh --host $(get_engine_url $app_name) iouPay id="$iou_id" Authorization:"Bearer $access_token" amount:=10

sleep 10

iou_state=$(./bash/client.sh --host $(get_engine_url $app_name) getIouByID id="$iou_id" Authorization:"Bearer $access_token" | jq -r '.["@state"]')
if [ -z "$iou_state" ]; then
	echo "IOU not found"
	exit 1
elif [ "$iou_state" != "unpaid" ]; then
	echo "IOU not reset to unpaid, state is $iou_state"
	exit 1
else
	echo "IOU paid, check complete"
fi

## Cleaning up

pid=$(ps -e | grep 'python-listener/app.py' | grep -v 'grep' | awk '{print $1}')

if [ -n "$pid" ]; then
    kill -9 "$pid"
    echo "Process python-listener/app.py with PID $pid has been killed."
else
    echo "No process found for python-listener/app.py."
    exit 1
fi

./cli app delete -app $app_id
