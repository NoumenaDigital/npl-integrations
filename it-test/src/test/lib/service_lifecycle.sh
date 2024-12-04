run_services() {
	local app_name_clean=$1
	. ./venv/bin/activate
	REALM="$app_name_clean" python python-listener/app.py &
}

## Cleaning up
kill_services() {
	local pid=$1

	echo "Killing listener service with PID $pid" >&2

	kill -9 "$pid"
}
