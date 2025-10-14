include .env

GITHUB_SHA=HEAD
MAVEN_CLI_OPTS?=--no-transfer-progress

KEYCLOAK_URL=https://keycloak-$(VITE_NC_TENANT_SLUG)-$(VITE_NC_APP_SLUG).$(NC_DOMAIN)
ENGINE_URL=https://engine-$(VITE_NC_TENANT_SLUG)-$(VITE_NC_APP_SLUG).$(NC_DOMAIN)
READ_MODEL_URL=https://engine-$(VITE_NC_TENANT_SLUG)-$(VITE_NC_APP_SLUG).$(NC_DOMAIN)/graphql
NPL_SOURCES=$(shell find npl/src/main -name \*npl)
WEBAPP_SOURCES=$(shell find webapp/src -type f -print; find webapp/public -type f -print; find webapp -maxdepth 1 \( -name "*.json" -o -name "*.html" -o -name "*.ts" \) -print)

CLI_LATEST_VERSION_URL=https://api.github.com/repos/NoumenaDigital/npl-cli/releases/latest
CLI_INSTALL_SCRIPT_URL=https://documentation.noumenadigital.com/get-npl-cli.sh

## Common commands
.PHONY:	install
install:	cli
	brew install jq python3

.PHONY:	install-openapi-generator
install-openapi-generator:
	@if ! command -v openapi-generator-cli >/dev/null 2>&1; then \
		npm install @openapitools/openapi-generator-cli prettier -g ; \
	fi

.PHONY:	cloud-install
cloud-install:	cli install-openapi-generator
	export PATH=~/.npl/bin:$$PATH
	echo "$$HOME/.npl/bin" >> "$$GITHUB_PATH"
	-sudo apt-get install jq

.PHONY:	clean
clean:
	docker compose down -v
	cd npl ; mvn $(MAVEN_CLI_OPTS) clean
	rm -rf **/target
	rm -rf target
	rm -rf **/node_modules
	rm -rf **/dist
	rm -rf **/build
	rm -rf **/venv
	rm -rf venv
	rm -rf **/generated
	rm -rf iou-python-client
	rm -rf openapi
	rm -rf bash
	rm -rf keycloak-provisioning/state.tfstate*
	rm -rf keycloak-provisioning/.terraform*
	rm -f cli
	rm -f *-openapi.yml

.PHONY:	format-check
format-check: venv python-libs iou-python-lib
	cd webapp && npm run format:ci
	. venv/bin/activate && cd python-listener && flake8
	. venv/bin/activate && cd streamlit-ui && flake8

.PHONY:	format
format:
	cd webapp && npm run format

.PHONY:	bump-platform-version
bump-platform-version:
	@if [ -z "$(PLATFORM_VERSION)" ]; then echo "PLATFORM_VERSION not set"; exit 1; fi
	perl -p -i -e's/PLATFORM_VERSION=.*/PLATFORM_VERSION=$(PLATFORM_VERSION)/' .env
	perl -p -i -e's/FROM ghcr.io\/noumenadigital\/packages\/engine:.*/FROM ghcr.io\/noumenadigital\/packages\/engine:$(PLATFORM_VERSION)/' npl/Dockerfile
	mvn -pl parent-pom versions:set-property -Dproperty=noumena.platform.version -DnewVersion="$(PLATFORM_VERSION)"

## NOUMENA CLOUD COMMANDS
cli:
	@if command -v npl >/dev/null 2>&1; then \
		CURRENT_VERSION=$$(npl version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1); \
		LATEST_VERSION=$$(curl -s "${CLI_LATEST_VERSION_URL}" | jq -r .tag_name | sed 's/^v//'); \
		if [ "$$CURRENT_VERSION" != "$$LATEST_VERSION" ]; then \
			if brew list npl >/dev/null 2>&1; then \
				brew upgrade npl; \
			elif [ -f "$$HOME/.npl/bin/npl" ]; then \
				curl -s "${CLI_INSTALL_SCRIPT_URL}" | bash; \
			else \
				echo "Manual installation detected. Please update manually or reinstall."; \
				exit 1; \
			fi; \
		fi; \
	else \
		curl -s "${CLI_INSTALL_SCRIPT_URL}" | bash; \
	fi

.PHONY:	clear-deploy
clear-deploy:	clear deploy

.PHONY:	clear
clear:
	@if [ -z "$(VITE_NC_TENANT_SLUG)" ] ; then echo "Tenant $(VITE_NC_TENANT_SLUG) not found"; exit 1; fi
	@if [ -z "$(VITE_NC_APP_SLUG)" ] ; then echo "App $(VITE_NC_APP_SLUG) not found"; exit 1; fi
	
	npl cloud clear npl --tenant $(VITE_NC_TENANT_SLUG) --app $(VITE_NC_APP_SLUG)

.PHONY:	deploy
deploy:	webapp-build $(NPL_SOURCES)
	@if [ -z "$(VITE_NC_TENANT_SLUG)" ] ; then echo "Tenant $(VITE_NC_TENANT_SLUG) not found"; exit 1; fi
	@if [ -z "$(VITE_NC_APP_SLUG)" ] ; then echo "App $(VITE_NC_APP_SLUG) not found"; exit 1; fi
	
	npl cloud deploy npl --tenant $(VITE_NC_TENANT_SLUG) --app $(VITE_NC_APP_SLUG) --migration npl/src/main/migration.yml
	npl cloud deploy frontend --tenant $(VITE_NC_TENANT_SLUG) --app $(VITE_NC_APP_SLUG) --frontend webapp/dist

## NPL SECTION

.PHONY:	npl-test
npl-test:
	npl test

openapi/iou-openapi.yml:	$(NPL_SOURCES)
	npl openapi --sourceDir npl/src/main

.PHONY: npl-docker
npl-docker:
	docker compose up --wait --build engine keycloak-provisioning

.PHONY:	npl-deploy
npl-deploy:	clear-deploy

## COMMON PYTHON SECTION

venv:	python-requirements.txt
	python3 -m venv venv

venv/.installed-libs: venv
	. venv/bin/activate; python3 -m pip install -r python-requirements.txt
	@touch venv/.installed-libs

@PHONY:	python-libs
python-libs:	venv/.installed-libs

iou-python-client:	openapi/iou-openapi.yml install-openapi-generator
	openapi-generator-cli generate --generator-name python --package-name iou --input-spec openapi/iou-openapi.yml --output iou-python-client
	@touch iou-python-client

venv/.installed-iou:	venv iou-python-client
	. venv/bin/activate ; pip install ./iou-python-client
	@touch venv/.installed-iou

.PHONY:	iou-python-lib
iou-python-lib:	venv/.installed-iou

## PYTHON LISTENER SECTION

.PHONY:	python-listener-run
python-listener-run:	python-libs iou-python-lib
	. venv/bin/activate && cd python-listener ; python3 app.py

.PHONY: python-listener-docker
python-listener-docker:	iou-python-client python-requirements.txt
	docker compose up --wait --build python-listener

.PHONY:	unit-tests-python-listener
unit-tests-python-listener:	venv python-libs iou-python-lib
	. venv/bin/activate && cd python-listener && PYTHONPATH=$(shell pwd) nosetests --verbosity=2 .

## STREAMLIT UI SECTION

.PHONY:	streamlit-ui-run
streamlit-ui-run:	python-libs iou-python-lib
	. venv/bin/activate && cd streamlit-ui ; streamlit run main.py

.PHONY:	streamlit-ui-docker
streamlit-ui-docker:	iou-python-client python-requirements.txt
	docker compose up --wait --build streamlit-ui

## WEBAPP SECTION

.PHONY:	webapp-client
webapp-client:	webapp/generated

webapp/generated:	openapi/iou-openapi.yml install-openapi-generator
	openapi-generator-cli generate --generator-name typescript-axios --additional-properties=useSingleRequestParameter=true --input-spec openapi/iou-openapi.yml --output webapp/generated
	@touch webapp/generated

webapp/node_modules:	webapp/package.json
	cd webapp ; npm install
	@touch webapp/node_modules

.PHONY: webapp-dependencies
webapp-dependencies: webapp/node_modules

.PHONY:	webapp-build
webapp-build:	webapp-client webapp/dist

webapp/dist:	$(WEBAPP_SOURCES)
	cd webapp ; npm run build
	@touch webapp/dist

.PHONY:	webapp-run
webapp-run:	webapp-client webapp-dependencies
	cd webapp ; npm run dev

webapp-docker:	webapp-client
	docker compose up --wait --build webapp

## IT-TEST SECTION

.PHONY:	it-test-client
it-test-client:	it-test/generated

it-test/generated:	openapi/iou-openapi.yml install-openapi-generator
	openapi-generator-cli generate --generator-name bash --input-spec openapi/iou-openapi.yml --output it-test/generated
	chmod +x ./it-test/generated/client.sh
	@touch it-test/generated

.PHONY:	it-test-dependencies
it-test-dependencies:

## ALL
.PHONY:	clients
clients:	iou-python-lib webapp-client it-test-client

.PHONY:	it-tests-cloud
it-tests-cloud:	python-libs iou-python-lib it-test-client cloud-install
	./it-test/src/test/it-cloud.sh

.PHONY:	it-tests-local
it-tests-local:	npl-docker python-listener-docker run-it-tests-local down

.PHONY:	run-it-tests-local
run-it-tests-local: it-test-client
	./it-test/src/test/it-local.sh

.PHONY:	up
up:	npl-docker webapp-docker streamlit-ui-docker python-listener-docker

.PHONY:	down
down:
	docker compose down -v

.PHONY:	run-only
run-only:
	make streamlit-ui-run & make python-listener-run & make webapp-run

.PHONY:	run
run:	npl-deploy run-only

.PHONY:	all
all:	up it-tests-local it-tests-cloud
