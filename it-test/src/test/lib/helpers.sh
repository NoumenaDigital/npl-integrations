get_keycloak_url() {
	local org_slug=$1
	local app_slug=$2
	echo "https://keycloak-$org_slug-$app_slug.$NC_DOMAIN"
}

get_engine_url() {
	local org_slug=$1
	local app_slug=$2
	echo "https://engine-$org_slug-$app_slug.$NC_DOMAIN"
}

get_read_model_url() {
	local org_slug=$1
	local app_slug=$2
	echo "https://engine-$org_slug-$app_slug.$NC_DOMAIN/graphql"
}
