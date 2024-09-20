GITHUB_SHA=HEAD
ENGINE_URL?=http://localhost:12000
KEYCLOAK_HEALTH_URL?=http://localhost:9000

.PHONY: health-check
health-check:
	curl -v $(KEYCLOAK_HEALTH_URL)/health
	curl -v $(ENGINE_URL)/actuator/health

.PHONY: install
install:
	mvn $(MAVEN_CLI_OPTS) install
	docker compose build

.PHONY:	run-only
run-only:
	docker compose up

.PHONY:	run
run: install run-only
