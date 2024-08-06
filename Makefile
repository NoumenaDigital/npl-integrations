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

.PHONY:	bump-platform-version
bump-platform-version:
	@if [ "$(PLATFORM_VERSION)" = "" ]; then echo "PLATFORM_VERSION not set"; exit 1; fi
	perl -p -i -e's/PLATFORM_VERSION=.*/PLATFORM_VERSION=$(PLATFORM_VERSION)/' .env
	mvn -pl parent-pom versions:set-property -Dproperty=noumena.platform.version -DnewVersion="$(PLATFORM_VERSION)"

.PHONY: zip
zip:
	@if [ "$(NPL_VERSION)" = "" ]; then echo "NPL_VERSION not set"; exit 1; fi
	@mkdir -p target && cd target && \
		cp -r ../npl/src/main/npl-* . && cp -r ../npl/src/main/yaml . && cp -r ../npl/src/main/kotlin-script . && \
		zip -r npl-integrations-$(NPL_VERSION).zip *

## Local commands
.PHONY: install
install:
	make -f local.mk install

.PHONY:	run-only
run-only:
	make -f local.mk run-only

.PHONY:	run
run: install run-only

## PaaS commands
.PHONY: first-install-paas
first-install-paas:
	make -f paas.mk first-install

.PHONY: install-paas
install-paas:
	make -f paas.mk install

run-paas:
	make -f paas.mk run

.PHONY:	run-only-paas
run-only-paas:
	make -f paas.mk run-only

download-cli:
	make -f paas.mk download-cli

.PHONY: create-app
create-app:
	make -f paas.mk create-app

clear-deploy: zip
	make -f paas.mk clear-deploy

.PHONY: status-app
status-app:
	make -f paas.mk status-app

.PHONY: iam
iam:
	make -f paas.mk iam
