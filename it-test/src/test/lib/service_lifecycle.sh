run_services() {
	local app_name_clean=$1

	. ./venv/bin/activate
	REALM="$app_name_clean" python python-listener/app.py &
    echo $!
}

## Cleaning up
kill_services() {
	local pid=$1

	kill -9 "$pid"
}
