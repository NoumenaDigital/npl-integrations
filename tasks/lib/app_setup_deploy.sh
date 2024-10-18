. ./tasks/lib/helpers.sh

zip_sources() {
	mkdir -p target
	mkdir -p target/src
	cp -R npl/src/main/npl-$NPL_VERSION target/src/
	cp -R npl/src/main/yaml target/src/
	cp -R npl/src/main/kotlin-script target/src/
	cd target/src
	zip -r ../npl-integrations-$NPL_VERSION.zip *
	cd ../..
}

populate_iam() {
	local app_name=$1
	local app_name_clean=$2
	local app_id=$3
	local my_realm_url=$4

	printf "Populating IAM for app %s with realm %s" "$app_name" "$my_realm_url" >&2

	local keycloak_user=$(get_nc_keycloak_username "$app_id")
	local keycloak_password=$(get_nc_keycloak_password "$app_id")
	local keycloak_url=$(get_keycloak_url "$app_name_clean")

	local token_url="$keycloak_url/realms/master/protocol/openid-connect/token"

	printf "fetching admin token: %s" "$token_url" >&2
	local admin_token=$(curl --location --request POST --header 'Content-Type: application/x-www-form-urlencoded' \
		--data-urlencode "username=$keycloak_user" \
		--data-urlencode "password=$keycloak_password" \
		--data-urlencode "client_id=admin-cli" \
		--data-urlencode "grant_type=password" \
		"$token_url" | jq -r '.access_token')

	curl --location --request DELETE "$keycloak_url/admin/realms/$app_name_clean" \
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

setup_deploy() {
	local app_id=$1
	local app_name=$2
	local app_name_clean=$3
	local realm_url=$4

	zip_sources

    ./cli app deploy -app "$app_id" -binary "./target/npl-integrations-$NPL_VERSION.zip"

    populate_iam "$app_name" "$app_name_clean" "$app_id" "$realm_url"
}
