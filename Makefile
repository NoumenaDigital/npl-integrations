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

escape_dollar = $(subst $$,\$$,$1)

## Common commands
.PHONY:	rename
rename:
	@if [ -z "$(PROJECT_NAME)" ]; then echo "PROJECT_NAME not set"; exit 1; fi
	perl -p -i -e's/npl-integrations/$(PROJECT_NAME)/g' `find . -type f`
	perl -p -i -e"s/nplintegrations/$(shell echo $(PROJECT_NAME) | tr '[:upper:]' '[:lower:]' | tr -d '-')/g" `find . -type f`
	@parent_dir=$$(basename "$$(pwd)") && \
	if [ "$$parent_dir" = "npl-integrations" ]; then \
		cd .. && mv npl-integrations $(PROJECT_NAME); \
	fi

.PHONY:	install
install:	cli
	brew install jq python3
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
	rm -rf bash
	rm -rf keycloak-provisioning/state.tfstate*
	rm -rf keycloak-provisioning/.terraform*
	rm -f cli
	rm -f *-openapi.yml

.PHONY:	format-check
format-check:
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

## Noumena Cloud commands
cli:
	curl -s "https://api.github.com/repos/NoumenaDigital/npl-cli/releases/tags/$(CLI_RELEASE_TAG)" \
		| jq --arg CLI_OS_ARCH "$(CLI_OS_ARCH)" '.assets[] | select(.name == $$CLI_OS_ARCH) | .url' -r \
		| xargs -t -n 2 -P 3 curl -sG -H "Accept: application/octet-stream" -Lo cli
	chmod +x cli

.PHONY:	create-app
create-app:
	./cli app create -org $(NC_ORG) -engine $(NC_ENGINE_VERSION) -name $(VITE_NC_APP_NAME) -provider MicrosoftAzure -trusted_issuers '["https://keycloak-$(VITE_NC_ORG_NAME)-$(VITE_NC_APP_NAME).$(NC_DOMAIN)/realms/$(VITE_NC_APP_NAME)"]'

.PHONY:	clear-deploy
clear-deploy:	cli zip
	@if [ -z "$(NC_APP)" ] ; then echo "App $(VITE_NC_APP_NAME) not found"; exit 1; fi
	@if [ -z "$(NPL_VERSION)" ]; then echo "NPL_VERSION not set"; exit 1; fi
	./cli app clear -app $(NC_APP)
	./cli app deploy -app $(NC_APP) -binary ./target/npl-integrations-$(NPL_VERSION).zip

.PHONY:	status-app
status-app:	cli
	./cli app detail -org $(NC_ORG) -app $(NC_APP)

.PHONY:	delete-app
delete-app:	cli
	@echo "Deleting app $(VITE_NC_APP_NAME) with id $(NC_APP)"
	@./cli app delete -app $(NC_APP)

.PHONY:	iam
iam:	cli
	-curl --location --request DELETE '$(KEYCLOAK_URL)/admin/realms/$(NC_APP_NAME_CLEAN)' \
		--header 'Content-Type: application/x-www-form-urlencoded' \
		--header "Authorization: Bearer $(shell curl --location --request POST --header 'Content-Type: application/x-www-form-urlencoded' \
			--data-urlencode 'username=$(NC_KEYCLOAK_USERNAME)' \
			--data-urlencode 'password=$(NC_KEYCLOAK_PASSWORD)' \
			--data-urlencode 'client_id=admin-cli' \
			--data-urlencode 'grant_type=password' \
			'$(KEYCLOAK_URL)/realms/master/protocol/openid-connect/token' | jq -r '.access_token')"
	cd keycloak-provisioning && \
		KEYCLOAK_USER=$(NC_KEYCLOAK_USERNAME) \
		KEYCLOAK_PASSWORD="$(call escape_dollar,$(NC_KEYCLOAK_PASSWORD))" \
		KEYCLOAK_URL=$(KEYCLOAK_URL) \
		TF_VAR_default_password=welcome \
		TF_VAR_systemuser_secret=super-secret-system-security-safe \
		TF_VAR_app_name=$(NC_APP_NAME_CLEAN) \
		./local.sh


.PHONY:	zip
zip:
	@if [ -z "$(NPL_VERSION)" ]; then echo "NPL_VERSION not set"; exit 1; fi
	@mkdir -p npl/src/main/kotlin-script && mkdir -p target && cd target && mkdir -p src && cd src && \
		cp -r ../../npl/src/main/npl-* . && cp -r ../../npl/src/main/yaml . && cp -r ../../npl/src/main/kotlin-script . && \
		zip -r ../npl-integrations-$(NPL_VERSION).zip *

## NPL SECTION

.PHONY:	npl-test
npl-test:
	cd npl ; mvn test

NPL_SOURCES=$(shell find npl/src/main -name \*npl)

iou-openapi.yml:	$(NPL_SOURCES)
	cd npl ; mvn package

npl-docker:	$(NPL_SOURCES)
	docker compose up --wait --build engine

npl-deploy:	clear-deploy

## PYTHON LISTENER SECTION

venv/bin/activate:
	python3 -m venv venv

.PHONY:	python-listener-client
python-listener-client:	venv/bin/activate python-listener/generated/openapi_client/api_client.py python-listener-dependencies

python-listener/generated/openapi_client/api_client.py:	iou-openapi.yml
	openapi-generator-cli generate --generator-name python --input-spec iou-openapi.yml --output python-listener/generated

.PHONY:	python-listener-dependencies
python-listener-dependencies:
	source venv/bin/activate && cd python-listener; python -m pip install -r requirements.txt

.PHONY:	python-listener-run
python-listener-run:	python-listener-client npl-deploy
	cd python-listener; python app.py

python-listener-docker:
	docker compose up --wait --build python-listener

unit-tests-python-listener:	python-listener-client
	. venv/bin/activate && cd python-listener && PYTHONPATH=$(shell pwd) nosetests --verbosity=2 .

## STREAMLIT UI SECTION

.PHONY:	streamlit-ui-client
streamlit-ui-client:	venv/bin/activate streamlit-ui/generated/openapi_client/api_client.py streamlit-ui-dependencies

streamlit-ui/generated/openapi_client/api_client.py:	iou-openapi.yml
	openapi-generator-cli generate --generator-name python --input-spec iou-openapi.yml --output streamlit-ui/generated

.PHONY:	streamlit-ui-dependencies
streamlit-ui-dependencies:
	source venv/bin/activate && cd streamlit-ui; python -m pip install -r requirements.txt

.PHONY:	streamlit-ui-run
streamlit-ui-run:	streamlit-ui-client
	source venv/bin/activate && cd streamlit-ui ; streamlit run main.py

streamlit-ui-docker:
	docker compose up --wait --build streamlit-ui

## WEBAPP SECTION

.PHONY:	webapp-client
webapp-client:	webapp/generated/openapi_client/api_client.py webapp-dependencies

webapp/generated/openapi_client/api_client.py:	iou-openapi.yml
	openapi-generator-cli generate --generator-name typescript-axios --additional-properties=useSingleRequestParameter=true --input-spec iou-openapi.yml --output webapp/generated

.PHONY:	webapp-dependencies
webapp-dependencies:
	cd webapp; npm i

.PHONY:	webapp-run
webapp-run:	webapp-client
	cd webapp; npm run dev

webapp-docker:
	docker compose up --wait --build webapp

## IT-TEST SECTION

.PHONY:	it-test-client
it-test-client:	it-test/generated/openapi_client/api_client.py

it-test/generated/openapi_client/api_client.py:	iou-openapi.yml
	openapi-generator-cli generate --generator-name bash --input-spec iou-openapi.yml --output it-test/generated
	chmod +x ./it-test/generated/client.sh

.PHONY:	it-test-dependencies
it-test-dependencies:

## ALL
clients:	python-listener-client streamlit-ui-client webapp-client it-test-client

docker:	npl-docker webapp-docker streamlit-ui-docker python-listener-docker

it-tests-cloud:	python-listener-client it-test-client
	./it-test/src/test/it-cloud.sh

it-tests-local:	npl-docker python-listener-docker run-it-tests-local down

run-it-tests-local: it-test-client
	./it-test/src/test/it-local.sh

.PHONY:	up
up:	docker

.PHONY:	down
down:
	docker compose down -v

.PHONY:	run
run:	npl-deploy streamlit-ui-run python-listener-run webapp-run

.PHONY:	all
all:	docker it-tests-local it-tests-cloud
