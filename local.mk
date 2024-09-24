GITHUB_SHA=HEAD
MAVEN_CLI_OPTS?=-s .m2/settings.xml --no-transfer-progress

.PHONY: install
install:
	mvn $(MAVEN_CLI_OPTS) install
	make build-images

.PHONY: build-images
build-images:
	docker compose build

.PHONY:	run-only
run-only:
	docker compose up

.PHONY:	run
run: install run-only

.PHONY: integration-tests
integration-tests:
	## Run all containers
	## python: Call endpoint to create and pay iou
	## python: Wait a few seconds
	## python: Expect the python service to have updated the iou state
