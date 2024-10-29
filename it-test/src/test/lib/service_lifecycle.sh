run_services() {
	local app_name_clean=$1

	. ./venv/bin/activate
	REALM="$app_name_clean" python python-listener/app.py &
}

## Cleaning up
kill_services() {
	process_ids=$(ps -e | grep 'python-listener/app.py' | grep -v 'grep' | awk '{print $1}')

	if [ -z "$process_ids" ]; then
		echo "No process found for python-listener/app.py" >&2
		exit 1
	else
		for pid in $process_ids;
		do
			kill -9 "$pid"
			echo "Process python-listener/app.py with PID $pid has been killed" >&2
		done
	fi
}
