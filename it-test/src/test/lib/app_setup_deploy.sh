. ./it-test/src/test/lib/helpers.sh

zip_sources() {
	mkdir -p target
	mkdir -p target/src
	cp -R npl/src/main/npl-"$NPL_VERSION" target/src/
	cp -R npl/src/main/yaml target/src/
	cp -R npl/src/main/kotlin-script target/src/
	cd target/src || exit
	zip -r ../npl-integrations-"$NPL_VERSION".zip ./*
	cd ../..
}

populate_iam() {
	local app_name=$1
	local app_name_clean=$2
	local app_id=$3
	local my_realm_url=$4

	local keycloak_user;
	local keycloak_password;
	local keycloak_url;
	local token_url;
	local admin_token;

	echo "Populating IAM for app $app_name with realm $my_realm_url" >&2

	keycloak_user=$(get_nc_keycloak_username "$app_id")
	keycloak_password=$(get_nc_keycloak_password "$app_id")
	keycloak_url=$(get_keycloak_url "$app_name_clean")

	token_url="$keycloak_url/realms/master/protocol/openid-connect/token"

	admin_token=$(curl --location --request POST --header 'Content-Type: application/x-www-form-urlencoded' \
		--data-urlencode "username=$keycloak_user" \
		--data-urlencode "password=$keycloak_password" \
		--data-urlencode "client_id=admin-cli" \
		--data-urlencode "grant_type=password" \
		"$token_url" | jq -r '.access_token')

	curl --location --request DELETE "$keycloak_url/admin/realms/$app_name_clean" \
		--header "Content-Type: application/x-www-form-urlencoded" \
		--header "Authorization: Bearer $admin_token"

	cd keycloak-provisioning || exit
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
