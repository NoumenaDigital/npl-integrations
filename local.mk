GITHUB_SHA=HEAD
MAVEN_CLI_OPTS?=-s .m2/settings.xml --no-transfer-progress

.PHONY: install
install:
	mvn $(MAVEN_CLI_OPTS) install
	make -f local.mk build-images

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
integration-tests: export ACCESS_TOKEN=$(shell curl -s 'http://localhost:11000/realms/nplintegrations/protocol/openid-connect/token' \
		 -H 'Content-Type: application/x-www-form-urlencoded' \
		 -d 'username=alice' \
		 -d 'password=alice' \
		 -d 'grant_type=password' \
		 -d 'client_id=nplintegrations' | jq -r .access_token)
integration-tests: install up
	IOU_ID=$(shell ./bash/client.sh --host localhost:12000 createIou Authorization:"Bearer ${ACCESS_TOKEN}" \
		description=="IOU from integration-test on $(shell date +%d.%m.%y) at $(shell date +%H:%M:%S)" \
		forAmount:=100 \
		@parties:='{"issuer":{"entity":{"email":["alice@noumenadigital.com"]},"access":{}},"payee":{"entity":{"email":["bob@noumenadigital.com"]},"access":{}}}' | jq -r '.["@id"]'); \
	./bash/client.sh --host localhost:12000 iouPay id="$$IOU_ID" Authorization:"Bearer $$ACCESS_TOKEN" amount:=10 | jq -r '.["@id"]'; \
	sleep 10; \
	IOU_STATE=$$( ./bash/client.sh --host localhost:12000 getIouByID id="$$IOU_ID" Authorization:"Bearer $$ACCESS_TOKEN" | jq -r '.["@state"]'); \
	if [[ $${IOU_STATE} = "payment_confirmation_required" ]]; then echo "IOU not unpaid"; exit 1; fi
	make -f local.mk down
