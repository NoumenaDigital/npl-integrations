New joiner: make install up
- from blank project
- run everything between cloud and non-docker services
- see that it works

Pipeline (ensure docker e2e and cloud e2e test pass): make npl-test cloud-install format-check unit-tests-python-listener integration-test-local integration-test-cloud
- from blank project
- check NPL
- generate clients
- build docker images
- run docker containers
- run e2e tests on docker containers
- upload NPL to cloud
- run services outside of docker
- run e2e tests on cloud

NPL Development: make npl-test or run in IntelliJ
- from existing project
- modify NPL
- run NPL tests

NPL & Client development: make something something-else
- from existing project
- modify NPL
- modify apps in python, kotlin, etc
- generate clients
- install clients if necessary
- run clients
- click around to check functionality
- maybe implement npl tests
