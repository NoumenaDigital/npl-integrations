create_app() {
	local nc_org=$1
	local app_name=$2
	local realm_url=$3

	echo "Creating app $app_name"
	app_id=$(./cli app create -org "$nc_org" -engine "$PAAS_ENGINE_VERSION" -name "$app_name" -provider MicrosoftAzure -trusted_issuers "[\"$realm_url\"]" | jq -r '.id')

	if [ -z "$app_id" ]; then
		echo "App creation failed"
		exit 1
	else
		echo "App created with ID $app_id"
	fi
	echo "$app_id"
}

get_app_details() {
	local app_id=$1
	local nc_org=$2
	./cli app detail -org "$nc_org" -app "$app_id"
}

check_app_status() {
	local app_id=$1
	local nc_org=$2
	get_app_details "$app_id" "$nc_org" | jq -r '.state'
}

waiting_for_activation() {
	local app_id=$1
	local nc_org=$2

	sleep_amount=0
    check_interval=10
    sleep $sleep_amount

    status=$(check_app_status "$app_id" "$nc_org")

    if [ -z "$status" ]; then
    	echo "App not found"
    	exit 1
    fi

    while [ "$status" != "active" ]; do
    	echo "App status: $status. Waiting for $check_interval seconds"
    	sleep $check_interval
    	sleep_amount=$((sleep_amount + $check_interval))
    	status=$(check_app_status "$app_id" "$nc_org")
    done

    echo "App active in less than $sleep_amount seconds."
    echo ""
}

delete_app() {
	local app_id=$1
	./cli app delete -app "$app_id"
}
