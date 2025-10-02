run_services() {
	local app_slug=$1
	. ./venv/bin/activate
	VITE_NC_APP_SLUG="$app_slug" python python-listener/app.py &
}

## Cleaning up
kill_services() {
	local pid=$1

	echo "Killing listener service with PID $pid" >&2

	kill -9 "$pid"
}
