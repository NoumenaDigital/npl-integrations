GITHUB_SHA=HEAD
MAVEN_CLI_OPTS?=-s .m2/settings.xml --no-transfer-progress

.PHONY: install
install:
	mvn $(MAVEN_CLI_OPTS) install
	docker-compose build

.PHONY:	run-only
run-only:
	docker-compose up

.PHONY:	run
run: install run-only
