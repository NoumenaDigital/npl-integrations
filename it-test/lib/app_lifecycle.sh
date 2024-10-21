create_app() {
	local nc_org=$1
	local app_name=$2
	local realm_url=$3

	echo "Creating app $app_name" >&2
	echo "nc_org: $nc_org" >&2
	echo "Realm URL: $realm_url" >&2

	app_id=$(./cli app create -org "$nc_org" -engine "$NC_ENGINE_VERSION" -name "$app_name" -provider MicrosoftAzure -trusted_issuers "[\"$realm_url\"]" | jq -r '.id')

	if [ -z "$app_id" ]; then
		printf "App creation failed\n" >&2
		exit 1
	else
		printf "App created with ID %s\n" "$app_id" >&2
	fi

	echo "$app_id"
}

check_app_status() {
	local app_id=$1
	local nc_org=$2
	./cli app detail -org "$nc_org" -app "$app_id" | jq -r '.state'
}

waiting_for_activation() {
	local app_id=$1
	local nc_org=$2

	sleep_amount=0
    check_interval=10
    sleep $sleep_amount

    status=$(check_app_status "$app_id" "$nc_org")

    if [ -z "$status" ]; then
    	printf "App not found" >&2
    	exit 1
    fi

    while [ "$status" != "active" ]; do
    	printf "App status: %s. Waiting for %s seconds" "$status" "$check_interval" >&2
    	sleep $check_interval
    	sleep_amount=$((sleep_amount + check_interval))
    	status=$(check_app_status "$app_id" "$nc_org")

    	if [ -z "$status" ]; then
			printf "App disappeared" >&2
			exit 1
		fi
    done

    printf "App active in less than %d seconds." "$sleep_amount" >&2
}

delete_app() {
	local app_id=$1
	./cli app delete -app "$app_id"
}
