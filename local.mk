GITHUB_SHA=HEAD
MAVEN_CLI_OPTS?=-s .m2/settings.xml --no-transfer-progress

ENGINE_URL?=http://localhost:12000
KEYCLOAK_HEALTH_URL?=http://localhost:9000

.PHONY: install
install:
	make -f local.mk maven-install
	chmod +x bash/client.sh
	make -f local.mk build-images

.PHONY: maven-install
maven-install:
	mvn clean $(MAVEN_CLI_OPTS) install

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

.PHONY: health-check
health-check:
	curl -v $(KEYCLOAK_HEALTH_URL)/health
	curl -v $(ENGINE_URL)/actuator/health

.PHONY: down
down:
	docker compose down -v

.PHONY: unit-tests-python-listener
unit-tests-python-listener:
	cd python-listener && PYTHONPATH=$(shell pwd) nosetests --verbosity=2 .

.PHONY: integration-test
integration-test: install up
	make -f local.mk run-integration-test
	make -f local.mk down

.PHONY: run-integration-test
run-integration-test:
	mvn $(MAVEN_CLI_OPTS) verify -pl it-test -P integration-test
