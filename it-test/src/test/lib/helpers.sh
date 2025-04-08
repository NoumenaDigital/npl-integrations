get_nc_app_name() {
	echo "it$(date +%y%m%d_%H%M%S)"
}

get_nc_app_name_clean() {
	local app_name=$1
	echo "$app_name" | tr -d '-' | tr -d '_'
}

get_nc_org() {
	./cli org list | jq --arg NC_ORG_NAME "$VITE_NC_ORG_NAME" -r '.[] | select(.slug == $NC_ORG_NAME) | .id'
}

get_nc_keycloak_username() {
	local app_id=$1
	./cli app secrets -app "$app_id" | jq -r '.iam_username'
}

get_nc_keycloak_password() {
	local app_id=$1
	./cli app secrets -app "$app_id" | jq -r '.iam_password'
}

get_keycloak_url() {
	local app_name_clean=$1
	echo "https://keycloak-$VITE_NC_ORG_NAME-$app_name_clean.$NC_DOMAIN"
}

get_engine_url() {
	local app_name_clean=$1
	echo "https://engine-$VITE_NC_ORG_NAME-$app_name_clean.$NC_DOMAIN"
}

get_read_model_url() {
	local app_name_clean=$1
	echo "https://engine-$VITE_NC_ORG_NAME-$app_name_clean.$NC_DOMAIN/graphql"
}
