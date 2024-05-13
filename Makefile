GITHUB_SHA=HEAD
VERSION?=1.0-SNAPSHOT
INFRA_DIR?=../infra
MAVEN_CLI_OPTS?=-s .m2/settings.xml --no-transfer-progress
LEVANT_VERSION=0.3.2

export NPL_VERSION=1.0
export NC_APP_NAME=nplintegrations
export NC_ORG_NAME=noumena
export NC_ORG := $(shell ./cli org list | jq --arg NC_ORG_NAME "$(NC_ORG_NAME)" -r '.[] | select(.slug == $$NC_ORG_NAME) | .id')
export NC_APP := $(shell ./cli app list -org $(NC_ORG) | jq --arg NC_APP_NAME "$(NC_APP_NAME)" '.[] | select(.name == $$NC_APP_NAME) | .id')
export NC_KEYCLOAK_USERNAME := $(shell ./cli app secrets -app $(NC_APP) | jq  -r '.iam_username')
export NC_KEYCLOAK_PASSWORD := $(shell ./cli app secrets -app $(NC_APP) | jq -r '.iam_password' )
export KEYCLOAK_URL=https://keycloak-$(NC_ORG_NAME)-$(NC_APP_NAME).shared-dev.noumenadigital.com
export ENGINE_URL=https://engine-$(NC_ORG_NAME)-$(NC_APP_NAME).shared-dev.noumenadigital.com
export READ_MODEL_URL=https://engine-$(NC_ORG_NAME)-$(NC_APP_NAME).shared-dev.noumenadigital.com/graphql

escape_dollar = $(subst $$,\$$,$1)

.PHONY:	clean
clean:
	mvn $(MAVEN_CLI_OPTS) clean

.PHONY: install
install:
	mvn $(MAVEN_CLI_OPTS) install
	cd python && python3 -m pip install -r requirements.txt
	cd webapp && npm run build

.PHONY:	format
format:
	mvn $(MAVEN_CLI_OPTS) ktlint:format

.PHONY:	run-only
run-only:
	docker compose up --wait

.PHONY:	run
run: format install run-only

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
		zip -r edu-$(NPL_VERSION).zip *

.PHONY: build-npl
build-npl:
	@echo "--> BUILDING NPL SOURCES"
	@(cd ./npl && make build-npl)

download-cli: export CLI_OS_ARCH=npl_darwin_amd64
download-cli: export RELEASE_TAG=1.2.0
download-cli: export API_URL=https://api.github.com/repos/NoumenaDigital/npl-cli/releases/tags/$(RELEASE_TAG)
download-cli:
	curl -s -H "Authorization: token $(GITHUB_USER_PASS)" $(API_URL) \
		| jq --arg CLI_OS_ARCH "$(CLI_OS_ARCH)" '.assets[] | select(.name == $$CLI_OS_ARCH) | .url' -r \
		| xargs -t -n 2 -P 3 curl -sG -H "Authorization: token $(GITHUB_USER_PASS)" -H "Accept: application/octet-stream" -Lo cli
	chmod +x cli

.PHONY: create-app
create-app:
	./cli app create -org $(NC_ORG) -engine 2024.1.0 -name $(NC_APP_NAME) -provider MicrosoftAzure -trusted_issuers '["https://keycloak-$(NC_ORG_NAME)-$(NC_APP_NAME).shared-dev.noumenadigital.com/realms/$(NC_APP_NAME)"]'

clear-deploy: zip
	@if [ "$(NC_APP)" = "" ] ; then echo "App $(NC_APP_NAME) not found"; exit 1; fi
	@if [ "$(NPL_VERSION)" = "" ]; then echo "NPL_VERSION not set"; exit 1; fi
	./cli app clear -app $(NC_APP)
	./cli app deploy -app $(NC_APP) -binary ./target/edu-$(NPL_VERSION).zip

.PHONY: status-app
status-app:
	./cli app detail -org $(NC_ORG) -app $(NC_APP)

.PHONY: iam
iam:
	# echo $(NC_KEYCLOAK_USERNAME) $(NC_KEYCLOAK_PASSWORD)
	-curl --location --request DELETE '$(KEYCLOAK_URL)/admin/realms/$(NC_APP_NAME)' \
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
		TF_VAR_app_name=$(NC_APP_NAME) \
		./local.sh