. ./it-test/src/test/lib/helpers.sh

populate_iam() {
	local app_slug=$1
	local my_realm_url=$2

	local keycloak_user;
	local keycloak_password;
	local keycloak_url;
	local token_url;
	local admin_token;

	echo "Populating IAM for app $app_slug with realm $my_realm_url" >&2

	keycloak_user=$(get_nc_keycloak_username "$app_slug")
	keycloak_password=$(get_nc_keycloak_password "$app_slug")
	keycloak_url=$(get_keycloak_url "$app_slug")

	token_url="$keycloak_url/realms/master/protocol/openid-connect/token"

	admin_token=$(curl --location --request POST --header 'Content-Type: application/x-www-form-urlencoded' \
		--data-urlencode "username=$keycloak_user" \
		--data-urlencode "password=$keycloak_password" \
		--data-urlencode "client_id=admin-cli" \
		--data-urlencode "grant_type=password" \
		"$token_url" | jq -r '.access_token')

	curl --location --request DELETE "$keycloak_url/admin/realms/$app_slug" \
		--header "Content-Type: application/x-www-form-urlencoded" \
		--header "Authorization: Bearer $admin_token"

	cd keycloak-provisioning || exit
	terraform init

	KEYCLOAK_USER=$keycloak_user \
	KEYCLOAK_PASSWORD=$keycloak_password \
	KEYCLOAK_URL=$keycloak_url \
	TF_VAR_default_password=welcome \
	TF_VAR_systemuser_secret=super-secret-system-security-safe \
	TF_VAR_app_slug=$app_slug \
	./local.sh

	cd ..
}

setup_deploy() {
	local app_slug=$1
	local realm_url=$2

	 npl cloud clear --tenant "$tenant_slug" --app "$app_slug"
	npl cloud deploy npl --tenant "$tenant_slug" --app "$app_slug" --migration ./npl/src/main/migration.yml

    # populate_iam "$app_slug" "$realm_url" # TODO - re-enable when we can create apps & users
}
