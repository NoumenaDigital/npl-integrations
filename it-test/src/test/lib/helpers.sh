get_keycloak_url() {
	local tenant_slug=$1
	local app_slug=$2
	echo "https://keycloak-$tenant_slug-$app_slug.$NC_DOMAIN"
}

get_engine_url() {
	local tenant_slug=$1
	local app_slug=$2
	echo "https://engine-$tenant_slug-$app_slug.$NC_DOMAIN"
}

get_read_model_url() {
	local tenant_slug=$1
	local app_slug=$2
	echo "https://engine-$tenant_slug-$app_slug.$NC_DOMAIN/graphql"
}
