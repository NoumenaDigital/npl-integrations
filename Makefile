GITHUB_SHA=HEAD
MAVEN_CLI_OPTS?=-s .m2/settings.xml --no-transfer-progress

## Common commands
.PHONY: rename
rename:
	@if [ "$(PROJECT_NAME)" = "" ]; then echo "PROJECT_NAME not set"; exit 1; fi
	perl -p -i -e's/npl-integrations/$(PROJECT_NAME)/g' `find . -type f`
	perl -p -i -e's/nplintegrations/$(shell echo $(PROJECT_NAME) | tr '[:upper:]' '[:lower:]' | tr -d '-')/g' `find . -type f`
	@parent_dir=$$(basename "$$(pwd)") && \
	if [ "$$parent_dir" = "npl-integrations" ]; then \
		cd .. && mv npl-integrations $(PROJECT_NAME); \
	fi

.PHONY:	clean
clean:
	docker compose down -v
	mvn $(MAVEN_CLI_OPTS) clean

.PHONY:	format-check
format-check:
	cd webapp && npm run format:ci
	cd webapp && npm run lint
	cd python-listener && flake8
	cd streamlit-ui && flake8

.PHONY:	format
format:
	cd webapp && npm run format

.PHONY:	bump-platform-version
bump-platform-version:
	@if [ "$(PLATFORM_VERSION)" = "" ]; then echo "PLATFORM_VERSION not set"; exit 1; fi
	perl -p -i -e's/PLATFORM_VERSION=.*/PLATFORM_VERSION=$(PLATFORM_VERSION)/' .env
	perl -p -i -e's/FROM ghcr.io\/noumenadigital\/packages\/engine:.*/FROM ghcr.io\/noumenadigital\/packages\/engine:$(PLATFORM_VERSION)/' npl/Dockerfile
	mvn -pl parent-pom versions:set-property -Dproperty=noumena.platform.version -DnewVersion="$(PLATFORM_VERSION)"

## Local commands
.PHONY: install
install:
	make -f local.mk install

.PHONY:	run-only
run-only:
	make -f local.mk run-only

.PHONY:	run
run: install run-only

## Noumena Cloud commands
.PHONY: first-install-cloud
first-install-cloud:
	make -f cloud.mk first-install

.PHONY: install-cloud
install-cloud:
	make -f cloud.mk install

run-cloud:
	make -f cloud.mk run

.PHONY:	run-only-cloud
run-only-cloud:
	make -f cloud.mk run-only

download-cli:
	make -f cloud.mk download-cli

.PHONY: create-app
create-app:
	make -f cloud.mk create-app

clear-deploy:
	make -f cloud.mk clear-deploy

.PHONY: status-app
status-app:
	make -f cloud.mk status-app

.PHONY: iam
iam:
	make -f cloud.mk iam

.PHONY: zip
zip:
	make -f cloud.mk zip

.PHONY: run-streamlit-ui
run-streamlit-ui:
	make -f cloud.mk run-streamlit-ui

.PHONY: integration-test-local
integration-test-local:
	make -f local.mk integration-test

.PHONY: integration-tests-cloud
integration-test-cloud:
	make -f cloud.mk integration-test

unit-tests-python-listener:
	make -f local.mk unit-tests-python-listener
