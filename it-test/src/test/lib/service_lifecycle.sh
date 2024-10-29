run_services() {
	local app_name_clean=$1

	echo "Starting listener service for $app_name_clean"
	. ./venv/bin/activate
	REALM="$app_name_clean" python3 python-listener/app.py &
    echo $!
}

## Cleaning up
kill_services() {
	local pid=$1

	kill -9 "$pid"
}
