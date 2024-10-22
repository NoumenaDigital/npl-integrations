GITHUB_SHA=HEAD
MAVEN_CLI_OPTS?=-s .m2/settings.xml --no-transfer-progress

.PHONY: install
install:
	mvn $(MAVEN_CLI_OPTS) install
	make -f local.mk build-images

.PHONY: build-images
build-images:
	docker compose build

.PHONY:	run-only
run-only:
	docker compose up

.PHONY:	run
run: install run-only

.PHONY: up
up:
	docker compose up -d

.PHONY: down
down:
	docker compose down -v

.PHONY: unit-tests-python-listener
unit-tests-python-listener:
	cd python-listener && PYTHONPATH=$(shell pwd) nosetests --verbosity=2 .

.PHONY: integration-test
integration-test: install up
	./it-test/it-local.sh
	make -f local.mk down
