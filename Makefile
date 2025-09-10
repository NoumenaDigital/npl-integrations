include .env

GITHUB_SHA=HEAD
MAVEN_CLI_OPTS?=--no-transfer-progress
CLI_OS_ARCH=npl_darwin_amd64
CLI_RELEASE_TAG=1.3.0

NC_APP_NAME_CLEAN := $(shell echo ${VITE_NC_APP_NAME} | tr -d '-' | tr -d '_')
NC_ORG := $(shell ./cli org list 2>/dev/null | jq --arg VITE_NC_ORG_NAME "$(VITE_NC_ORG_NAME)" -r '.[] | select(.slug == $$VITE_NC_ORG_NAME) | .id' 2>/dev/null)
NC_APP := $(shell ./cli app list -org $(NC_ORG) 2>/dev/null | jq --arg VITE_NC_APP_NAME "$(VITE_NC_APP_NAME)" '.[] | select(.slug == $$VITE_NC_APP_NAME) | .id' 2>/dev/null)
NC_KEYCLOAK_USERNAME := $(shell ./cli app secrets -app $(NC_APP) 2>/dev/null | jq -r '.iam_username' 2>/dev/null )
NC_KEYCLOAK_PASSWORD := $(shell ./cli app secrets -app $(NC_APP) 2>/dev/null | jq -r '.iam_password' 2>/dev/null )
KEYCLOAK_URL=https://keycloak-$(VITE_NC_ORG_NAME)-$(NC_APP_NAME_CLEAN).$(NC_DOMAIN)
ENGINE_URL=https://engine-$(VITE_NC_ORG_NAME)-$(VITE_NC_APP_NAME).$(NC_DOMAIN)
READ_MODEL_URL=https://engine-$(VITE_NC_ORG_NAME)-$(VITE_NC_APP_NAME).$(NC_DOMAIN)/graphql
NPL_SOURCES=$(shell find npl/src/main -name \*npl)
TF_SOURCES=$(shell find keycloak-provisioning -name \*tf)

escape = $(subst $$,\$$,$1)

## Common commands
.PHONY:	install
install:	cli
	brew install jq python@3.12 terraform
	npm install @openapitools/openapi-generator-cli prettier -g

.PHONY:	cloud-install
cloud-install:	cli
	-sudo apt-get install jq
	npm install @openapitools/openapi-generator-cli prettier -g

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
	curl -s "https://api.github.com/repos/NoumenaDigital/npl-cli/releases/tags/$(CLI_RELEASE_TAG)" \
		| jq --arg CLI_OS_ARCH "$(CLI_OS_ARCH)" '.assets[] | select(.name == $$CLI_OS_ARCH) | .url' -r \
		| xargs -t -n 2 -P 3 curl -sG -H "Accept: application/octet-stream" -Lo cli
	chmod +x cli

.PHONY:	create-app
create-app:
	./cli app create -org $(NC_ORG) -engine $(NC_ENGINE_VERSION) -name $(VITE_NC_APP_NAME) -provider MicrosoftAzure -trusted_issuers '["https://keycloak-$(VITE_NC_ORG_NAME)-$(VITE_NC_APP_NAME).$(NC_DOMAIN)/realms/$(VITE_NC_APP_NAME)"]'

.PHONY:	clear-deploy
clear-deploy:	zip
	@if [ -z "$(NC_APP)" ] ; then echo "App $(VITE_NC_APP_NAME) not found"; exit 1; fi
	@if [ -z "$(NPL_VERSION)" ]; then echo "NPL_VERSION not set"; exit 1; fi
	./cli app clear -app $(NC_APP)
	./cli app deploy -app $(NC_APP) -binary ./target/npl-integrations-$(NPL_VERSION).zip

.PHONY:	status-app
status-app:
	./cli app detail -org $(NC_ORG) -app $(NC_APP)

.PHONY:	delete-app
delete-app:
	@echo "Deleting app $(VITE_NC_APP_NAME) with id $(NC_APP)"
	@./cli app delete -app $(NC_APP)

iam:	$(TF_SOURCES)
	-@curl -s --location --request DELETE '$(KEYCLOAK_URL)/admin/realms/$(NC_APP_NAME_CLEAN)' \
		--header 'Content-Type: application/x-www-form-urlencoded' \
		--header "Authorization: Bearer $(shell curl -s --location --request POST --header 'Content-Type: application/x-www-form-urlencoded' \
			--data-urlencode 'username=$(NC_KEYCLOAK_USERNAME)' \
			--data-urlencode 'password=$(NC_KEYCLOAK_PASSWORD)' \
			--data-urlencode 'client_id=admin-cli' \
			--data-urlencode 'grant_type=password' \
			'$(KEYCLOAK_URL)/realms/master/protocol/openid-connect/token' | jq -r '.access_token')"
	cd keycloak-provisioning && \
		KEYCLOAK_USER=$(NC_KEYCLOAK_USERNAME) \
		KEYCLOAK_PASSWORD="$(call escape,$(NC_KEYCLOAK_PASSWORD))" \
		KEYCLOAK_URL=$(KEYCLOAK_URL) \
		TF_VAR_default_password=welcome \
		TF_VAR_systemuser_secret=super-secret-system-security-safe \
		TF_VAR_app_name=$(NC_APP_NAME_CLEAN) \
		./local.sh

.PHONY:	zip
zip:	target/npl-integrations-$(NPL_VERSION).zip

target/npl-integrations-$(NPL_VERSION).zip:	$(NPL_SOURCES)
	@if [ -z "$(NPL_VERSION)" ]; then echo "NPL_VERSION not set"; exit 1; fi
	@mkdir -p npl/src/main/kotlin-script && mkdir -p target && cd target && mkdir -p src && cd src && \
		cp -r ../../npl/src/main/npl-* . && cp -r ../../npl/src/main/yaml . && cp -r ../../npl/src/main/kotlin-script . && \
		zip -r ../npl-integrations-$(NPL_VERSION).zip *

## NPL SECTION

.PHONY:	npl-test
npl-test:
	cd npl ; mvn test

iou-openapi.yml:	$(NPL_SOURCES)
	cd npl ; mvn package

.PHONY: npl-docker
npl-docker:
	docker compose up --wait --build engine keycloak-provisioning

.PHONY:	npl-deploy
npl-deploy:	clear-deploy

## COMMON PYTHON SECTION

venv:	python-requirements.txt
	python3.12 -m venv venv

venv/.installed-libs: venv
	. venv/bin/activate; python3 -m pip install --upgrade pip
	. venv/bin/activate; python3 -m pip install -r python-requirements.txt
	@touch venv/.installed-libs

@PHONY:	python-libs
python-libs:	venv/.installed-libs

iou-python-client:	iou-openapi.yml
	openapi-generator-cli generate --generator-name python --package-name iou --input-spec iou-openapi.yml --output iou-python-client
	@touch iou-python-client

venv/.installed-iou:	venv iou-python-client
	cat iou-python-client/pyproject.toml
	. venv/bin/activate ; python3 -m pip install ./iou-python-client
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

webapp/generated:	iou-openapi.yml
	openapi-generator-cli generate --generator-name typescript-axios --additional-properties=useSingleRequestParameter=true --input-spec iou-openapi.yml --output webapp/generated
	@touch webapp/generated

webapp/node_modules:	webapp/package.json
	cd webapp ; npm install
	@touch webapp/node_modules

.PHONY: webapp-dependencies
webapp-dependencies: webapp/node_modules

.PHONY:	webapp-run
webapp-run:	webapp-client webapp-dependencies
	cd webapp ; npm run dev

webapp-docker:	webapp-client
	docker compose up --wait --build webapp

## IT-TEST SECTION

.PHONY:	it-test-client
it-test-client:	it-test/generated

it-test/generated:	iou-openapi.yml
	openapi-generator-cli generate --generator-name bash --input-spec iou-openapi.yml --output it-test/generated
	chmod +x ./it-test/generated/client.sh
	@touch it-test/generated

.PHONY:	it-test-dependencies
it-test-dependencies:

## ALL
.PHONY:	clients
clients:	iou-python-lib webapp-client it-test-client

.PHONY:	it-tests-cloud
it-tests-cloud:	iou-python-lib it-test-client
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
