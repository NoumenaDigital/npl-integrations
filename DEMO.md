# npl-integrations demo

## Focus of this demo
The demo steps detailed below illustrate
- How various components of the `npl-integrations` example application (with python "callback service" and typescript frontend) can be deployed locally, using docker, or integrated with an engine and keycloak deployed to PaaS
- The various APIs exposed by the engine and how users can interact with them to execute actions, retrieve a history of state changes or commands, listen to event streams...

## Pre-requisites
Follow the configuration steps detailed in `README.md` and make sure you can run the components detailed therein.

## Part 1: Local deployment of engine and keycloak
**Step 1:** Deploy the NPL in an engine running locally, using docker: `docker compose up -d --build engine keycloak-provisioning`
Notes:
- The `--build` flag in docker compose ensures that if containers are recreated, images are rebuilt first from the latest sources. 
- Look at the deployed containers using the Docker Desktop app or typing `docker ps -a`. You should see the engine and its database running, as well as keycloak and its database.
- Keycloak has been provisioned with users Alice, Bob and Eve. A container `keycloak-provisioning` should show up as exited among docker containers since provisioning has completed. For technical details on the provisioning, follow the trail from the `keycloak-provisioning` service in `docker-compose.yml` to script `local.sh` and terraform file `terraform.tf` in module `keycloak-provisioning`.
- Open the keycloak administration console accessible under `http://keycloak:11000/admin/master/console/` (also via `http://keycloak:11000`)