GITHUB_SHA=HEAD
MAVEN_CLI_OPTS?=-s .m2/settings.xml --no-transfer-progress

.PHONY: install
install:
	mvn $(MAVEN_CLI_OPTS) install
	make build-images

.PHONY: build-images
build-images:
	docker compose build

.PHONY:	run-only
run-only:
	docker compose up

.PHONY:	run
run: install run-only

.PHONY: up
up:
	docker compose up -d

.PHONY: down
down:
	docker compose down -v

.PHONY: integration-tests
integration-tests:
	ACCESS_TOKEN=$(shell curl -s 'http://localhost:11000/realms/nplintegrations/protocol/openid-connect/token' \
		 -H 'Content-Type: application/x-www-form-urlencoded' \
		 -d 'username=alice' \
		 -d 'password=alice' \
		 -d 'grant_type=password' \
		 -d 'client_id=nplintegrations' | jq -r .access_token); \
	# echo "ACCESS_TOKEN: $$ACCESS_TOKEN"; \
	./bash/client.sh --host localhost:12000 createIou Authorization:"Bearer $$ACCESS_TOKEN" \
		"description"="my iou" \
		"forAmount"=100 \
		"Atparties"='{ "issuer": { "entity" : { "email": [ "alice@noumenadigital.com" ] }, "access": {}} "payee": { "entity" : { "email": [ "alice@noumenadigital.com" ] }, "access": {}} }'
	# curl -X POST http://localhost:12000/npl/iou/create -H "Content-Type: application/json" -d \
	# 	'{"description": "1", "forAmount": 100, "@parties": { "issuer": { "entity" : { "email": [ "alice@noumenadigital.com" ] }, "access": {}}, "payee": { "entity" : { "email": [ "alice@noumenadigital.com" ] }, "access": {}} }}'
	## python: Call endpoint to create and pay iou
	## python: Wait a few seconds
	## python: Expect the python service to have updated the iou state
	# make -f local.mk down
