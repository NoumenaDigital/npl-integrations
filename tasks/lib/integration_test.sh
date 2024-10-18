
run_integration_tests() {
	local app_name_clean=$1
	local engine_url=$2
	local realm_url=$3

	access_token=$(app_auth "$realm_url" "$app_name_clean")

	iou_id=$(create_iou "$engine_url" "$access_token")

	pay_iou "$engine_url" "$access_token" "$iou_id"

	sleep 10

	check_iou_repayment "$engine_url" "$access_token" "$iou_id"
}

app_auth() {
	local realm_url=$1
	local app_name_clean=$2

	local access_token=$(curl -s "$realm_url/protocol/openid-connect/token" \
		-H 'Content-Type: application/x-www-form-urlencoded' \
		-d 'username=alice' \
		-d 'password=alice' \
		-d 'grant_type=password' \
		-d "client_id=$app_name_clean" | jq -r '.access_token')

	if [ -z "$access_token" ]; then
		echo "Access token not found"
		exit 1
	fi
	echo "$access_token"
}

create_iou() {
	local engine_url=$1
	local access_token=$2

	var iou_id=$(./bash/client.sh --host "$engine_url" createIou Authorization:"Bearer $access_token" \
		description=="IOU from integration-test on $(date +%d.%m.%y_%H:%M:%S)" \
		forAmount:=100 \
		@parties:='{"issuer":{"entity":{"email":["alice@noumenadigital.com"]},"access":{}},"payee":{"entity":{"email":["bob@noumenadigital.com"]},"access":{}}}' | jq -r '.["@id"]')

	if [ -z "$iou_id" ]; then
		echo "Iou not created"
		exit 1
	else
		echo "IOU created with ID $iou_id"
	fi
	echo "$iou_id"
}

pay_iou() {
	local engine_url=$1
	local access_token=$2
	local iou_id=$3

	./bash/client.sh --host "$engine_url" iouPay id="$iou_id" Authorization:"Bearer $access_token" amount:=10
}

check_iou_repayment() {
	local engine_url=$1
	local access_token=$2
	local iou_id=$3

	iou_state=$(./bash/client.sh --host "$engine_url" getIouByID id="$iou_id" Authorization:"Bearer $access_token" | jq -r '.["@state"]')
	if [ -z "$iou_state" ]; then
		echo "IOU not found"
		exit 1
	elif [ "$iou_state" != "unpaid" ]; then
		echo "IOU not reset to unpaid, state is $iou_state"
		exit 1
	else
		echo "IOU paid, check complete"
	fi
}
