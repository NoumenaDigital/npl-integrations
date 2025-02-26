GITHUB_SHA=HEAD
MAVEN_CLI_OPTS?=--no-transfer-progress

## Common commands
.PHONY: install
install:
	make -f cloud.mk first-install
	make -f local.mk install

.PHONY: cloud-install
cloud-install:
	make -f cloud.mk pipeline-setup
	make -f cloud.mk install

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
	rm -rf **/target
	rm -rf **/node_modules
	rm -rf **/dist
	rm -rf **/build
	rm -rf **/venv
	rm -rf **/generated
	rm -rf bash
	rm -rf keycloak-provisioning/state.tfstate*
	rm -rf keycloak-provisioning/.terraform*
	rm -f cli

.PHONY:	format-check
format-check:
	cd webapp && npm run format:ci
	cd webapp && npm run lint
	. venv/bin/activate && cd python-listener && flake8
	. venv/bin/activate && cd streamlit-ui && flake8

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
.PHONY: install-python
install-python:
	make -f cloud.mk install-python

.PHONY: install-webapp
install-webapp:
	make -f cloud.mk install-webapp

.PHONY: generate-sources
generate-sources:
	mvn $(MAVEN_CLI_OPTS) generate-sources && chmod +x bash/client.sh

.PHONY:	run-only
run-only:
	make -f local.mk run-only

.PHONY:	up
up:
	make -f local.mk up

.PHONY:	run
run: install run-only

.PHONY: run-python-listener
run-python-listener:
	make -f cloud.mk run-python-listener

.PHONY: run-streamlit-ui
run-streamlit-ui:
	make -f cloud.mk run-streamlit-ui

.PHONY: run-webapp
run-webapp:
	make -f cloud.mk run-webapp

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

.PHONY: integration-test-local
integration-test-local:
	make -f local.mk integration-test

.PHONY: integration-tests-cloud
integration-test-cloud:
	make -f cloud.mk integration-test

unit-tests-python-listener:
	. venv/bin/activate && make -f local.mk unit-tests-python-listener

.PHONY:	npl-test
npl-test:
	cd npl ; mvn test

NPL_SOURCES=$(shell find npl/src/main -name \*npl)

iou-openapi.yml:	$(NPL_SOURCES)
	cd npl ; mvn package

## NPL SECTION

npl-docker:
	docker compose up --wait --build engine

npl-deploy: clear-deploy

## PYTHON SECTION

.PHONY:	python-client
python-listener-client:	python-listener/generated/openapi_client/api_client.py
	source venv/bin/activate && cd streamlit-ui; python -m pip install -r requirements.txt

python-listener/generated/openapi_client/api_client.py:	iou-openapi.yml
	openapi-generator generate --generator-name python --input-spec iou-openapi.yml --output python-listener/generated

.PHONY:	python-listener-dependencies
python-listener-dependencies:
	cd python-listener; pip install -r requirements

.PHONY: python-listener-run
python-listener-run:	python-listener-client npl-deploy
	cd python-listener; python app.py

python-listener-docker:
	docker compose up --wait --build python-listener

## STREAMLIT SECTION

.PHONY:	streamlit-ui-client
streamlit-ui-client:	streamlit-ui/generated/openapi_client/api_client.py
	source venv/bin/activate && cd streamlit-ui; python -m pip install -r requirements.txt

streamlit-ui/generated/openapi_client/api_client.py:	iou-openapi.yml
	openapi-generator generate --generator-name python --input-spec iou-openapi.yml --output streamlit-ui/generated

.PHONY:	streamlit-dependencies
streamlit-ui-dependencies:
	cd streamlit-ui; pip install -r requirements

.PHONY: streamlit-ui-run
streamlit-ui-run:	streamlit-ui-client npl-docker
	cd streamlit-ui; streamlit run main.py

streamlit-ui-docker:
	docker compose up --wait --build streamlit-ui

## WEB SECTION

.PHONY:	webapp-client
webapp-client:	webapp/generated/openapi_client/api_client.py
	source venv/bin/activate && cd webapp; python -m pip install -r requirements.txt

webapp/generated/openapi_client/api_client.py:	iou-openapi.yml
	openapi-generator generate --generator-name typescript-axios --input-spec iou-openapi.yml --output webapp/generated

.PHONY:	streamlit-dependencies
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
	source venv/bin/activate && cd it-test; python -m pip install -r requirements.txt

it-test/generated/openapi_client/api_client.py:	iou-openapi.yml
	openapi-generator generate --generator-name python --input-spec iou-openapi.yml --output it-test/generated

.PHONY:	streamlit-dependencies
it-test-dependencies:

## ALL
docker: npl-docker webapp-docker streamlit-ui-docker python-listener-docker

it-tests-cloud:	npl-deploy streamlit-ui-docker python-listener-docker it-test-client
	./it-test/src/test/it-local.sh

it-tests-local:	npl-docker webapp-docker streamlit-ui-docker python-listener-docker it-test-client
	./it-test/src/test/it-local.sh

.PHONY: up
up:	docker

.PHONY: down
down:
	docker compose down -v

.PHONY: run
run:	npl-deploy streamlit-ui-run python-listener-run webapp-run

.PHONY:	all
all:	docker it-tests-local it-tests-cloud
