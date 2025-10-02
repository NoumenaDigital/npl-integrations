create_app() {
	local org_slug=$1
	local app_name=$2
	local realm_url=$3

	echo "Creating app $app_name in org $org_slug" >&2

	app_slug=$(./cli app create -org "$org_slug" -engine "$NC_ENGINE_VERSION" -name "$app_name" -provider MicrosoftAzure -trusted_issuers "[\"$realm_url\"]" | jq -r '.id')

	if [ -z "$app_slug" ]; then
		echo "App creation failed" >&2
		exit 1
	else
		echo "App created with ID $app_slug" >&2
	fi

	echo "$app_slug"
}

check_app_status() {
	local app_slug=$1
	local org_slug=$2
	./cli app detail -org "$org_slug" -app "$app_slug" | jq -r '.state'
}

waiting_for_activation() {
	local app_slug=$1
	local org_slug=$2

	sleep_amount=0
    check_interval=10
    sleep $sleep_amount

    status=$(check_app_status "$app_slug" "$org_slug")

    if [ -z "$status" ]; then
    	echo "App not found" >&2
    	exit 1
    fi

    while [ "$status" != "active" ]; do
    	echo "App status: $status. Waiting for $check_interval seconds" >&2
    	sleep $check_interval
    	sleep_amount=$((sleep_amount + check_interval))
    	status=$(check_app_status "$app_slug" "$org_slug")

    	if [ -z "$status" ]; then
			echo "App disappeared" >&2
			exit 1
		fi
    done

    echo "App active in less than $sleep_amount seconds" >&2
}

delete_app() {
	local app_slug=$1
	./cli app delete -app "$app_slug"
}
