
run_services() {
	local app_name_clean=$1

	-. ./venv/bin/activate
	REALM="$app_name_clean" python python-listener/app.py &
}

## Cleaning up
kill_services() {
	pid=$(ps -e | grep 'python-listener/app.py' | grep -v 'grep' | awk '{print $1}')

	if [ -n "$pid" ]; then
		kill -9 "$pid"
		echo "Process python-listener/app.py with PID $pid has been killed."
	else
		echo "No process found for python-listener/app.py."
		exit 1
	fi
}
