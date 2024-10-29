GITHUB_SHA=HEAD
MAVEN_CLI_OPTS?=-s .m2/settings.xml --no-transfer-progress

CLI_OS_ARCH=npl_darwin_amd64
CLI_RELEASE_TAG=1.3.0
NPL_VERSION=1.0
NC_ENGINE_VERSION=2024.1.8
NC_DOMAIN=noumena.cloud
NC_APP_NAME=nplintegrations
NC_ORG_NAME=training
NC_APP_NAME_CLEAN := $(shell echo $(NC_APP_NAME) | tr -d '-' | tr -d '_')
NC_ORG := $(shell ./cli org list 2>/dev/null | jq --arg NC_ORG_NAME "$(NC_ORG_NAME)" -r '.[] | select(.slug == $$NC_ORG_NAME) | .id' 2>/dev/null)
NC_APP := $(shell ./cli app list -org $(NC_ORG) 2>/dev/null | jq --arg NC_APP_NAME "$(NC_APP_NAME)" '.[] | select(.name == $$NC_APP_NAME) | .id' 2>/dev/null)
NC_KEYCLOAK_USERNAME := $(shell ./cli app secrets -app $(NC_APP) 2>/dev/null | jq -r '.iam_username' 2>/dev/null )
NC_KEYCLOAK_PASSWORD := $(shell ./cli app secrets -app $(NC_APP) 2>/dev/null | jq -r '.iam_password' 2>/dev/null )
KEYCLOAK_URL=https://keycloak-$(NC_ORG_NAME)-$(NC_APP_NAME_CLEAN).$(NC_DOMAIN)
ENGINE_URL=https://engine-$(NC_ORG_NAME)-$(NC_APP_NAME).$(NC_DOMAIN)
READ_MODEL_URL=https://engine-$(NC_ORG_NAME)-$(NC_APP_NAME).$(NC_DOMAIN)/graphql

escape_dollar = $(subst $$,\$$,$1)

.PHONY: first-install
first-install:
	-brew install jq python3
	-sudo apt-get install jq
	make download-cli
	python3 -m venv ./venv; \
	. venv/bin/activate
	make install

.PHONY: pipeline-setup
pipeline-setup:
	-sudo apt-get install jq
	CLI_OS_ARCH=npl_linux_amd64 make -e -f cloud.mk download-cli
	make install
	python3 -m venv ./venv

.PHONY: install
install:
	mvn $(MAVEN_CLI_OPTS) install
	. venv/bin/activate && cd python-listener && python3 -m pip install -r requirements.txt
	. venv/bin/activate && cd streamlit-ui && python3 -m pip install -r requirements.txt
	cd webapp && npm install

.PHONY: install-python
install-python:
	mvn $(MAVEN_CLI_OPTS) install
	cd python-listener && python3 -m pip install -r requirements.txt
	cd streamlit-ui && python3 -m pip install -r requirements.txt

.PHONY:	run-only
run-only:
	make run-webapp & make run-python-listener & make run-streamlit-ui

.PHONY: run-webapp
run-webapp:
	cd webapp && npm run dev

.PHONY: run-python-listener
run-python-listener:
	cd python-listener && REALM=$(NC_APP_NAME) ORG=$(NC_ORG_NAME) python app.py

.PHONY: run-streamlit-ui
run-streamlit-ui:
	cd streamlit-ui && REALM=$(NC_APP_NAME) ORG=$(NC_ORG_NAME) streamlit run main.py

.PHONY:	run
run: install run-only

.PHONY: zip
zip:
	@if [ "$(NPL_VERSION)" = "" ]; then echo "NPL_VERSION not set"; exit 1; fi
	@mkdir -p npl/src/main/kotlin-script && @mkdir -p target && cd target && mkdir -p src && cd src && \
		cp -r ../../npl/src/main/npl-* . && cp -r ../../npl/src/main/yaml . && cp -r ../../npl/src/main/kotlin-script . && \
		zip -r ../npl-integrations-$(NPL_VERSION).zip *

.PHONY: download-cli
download-cli:
	curl -s "https://api.github.com/repos/NoumenaDigital/npl-cli/releases/tags/$(CLI_RELEASE_TAG)" \
		| jq --arg CLI_OS_ARCH "$(CLI_OS_ARCH)" '.assets[] | select(.name == $$CLI_OS_ARCH) | .url' -r \
		| xargs -t -n 2 -P 3 curl -sG -H "Accept: application/octet-stream" -Lo cli
	chmod +x cli

.PHONY: create-app
create-app:
	./cli app create -org $(NC_ORG) -engine $(NC_ENGINE_VERSION) -name $(NC_APP_NAME) -provider MicrosoftAzure -trusted_issuers '["https://keycloak-$(NC_ORG_NAME)-$(NC_APP_NAME).$(NC_DOMAIN)/realms/$(NC_APP_NAME)"]'

clear-deploy: zip
	@if [ "$(NC_APP)" = "" ] ; then echo "App $(NC_APP_NAME) not found"; exit 1; fi
	@if [ "$(NPL_VERSION)" = "" ]; then echo "NPL_VERSION not set"; exit 1; fi
	./cli app clear -app $(NC_APP)
	./cli app deploy -app $(NC_APP) -binary ./target/npl-integrations-$(NPL_VERSION).zip

.PHONY: status-app
status-app:
	./cli app detail -org $(NC_ORG) -app $(NC_APP)

.PHONY: delete
delete:
	@echo "Deleting app $(NC_APP_NAME) with id $(NC_APP)"
	make -f cloud.mk status-app
	@./cli app delete -app $(NC_APP)

.PHONY: iam
iam:
	-curl --location --request DELETE '$(KEYCLOAK_URL)/admin/realms/$(NC_APP_NAME_CLEAN)' \
		--header 'Content-Type: application/x-www-form-urlencoded' \
		--header 'Authorization: Bearer $(shell curl --location --request POST --header 'Content-Type: application/x-www-form-urlencoded' \
			--data-urlencode 'username=$(NC_KEYCLOAK_USERNAME)' \
			--data-urlencode 'password=$(NC_KEYCLOAK_PASSWORD)' \
			--data-urlencode 'client_id=admin-cli' \
			--data-urlencode 'grant_type=password' \
			'$(KEYCLOAK_URL)/realms/master/protocol/openid-connect/token' | jq -r '.access_token')'
	cd keycloak-provisioning && \
		KEYCLOAK_USER=$(NC_KEYCLOAK_USERNAME) \
		KEYCLOAK_PASSWORD="$(call escape_dollar,$(NC_KEYCLOAK_PASSWORD))" \
		KEYCLOAK_URL=$(KEYCLOAK_URL) \
		TF_VAR_default_password=welcome \
		TF_VAR_systemuser_secret=super-secret-system-security-safe \
		TF_VAR_app_name=$(NC_APP_NAME_CLEAN) \
		./local.sh

.PHONY: integration-test
integration-test:
	NC_ENGINE_VERSION=$(NC_ENGINE_VERSION) \
	NC_DOMAIN=$(NC_DOMAIN) \
	NC_ORG_NAME=$(NC_ORG_NAME) \
	NPL_VERSION=$(NPL_VERSION) \
	NC_ENV=$(NC_ENV) \
	./it-test/src/test/it-cloud.sh
