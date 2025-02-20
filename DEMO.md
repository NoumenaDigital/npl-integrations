# npl-integrations demo

## Focus of this demo
The demo steps detailed below illustrate
- How various components of the `npl-integrations` example application (with python "listener and callback service" and typescript frontend) can be deployed locally, using docker, or integrated with an engine and keycloak deployed to PaaS/Noumena Cloud
- The various APIs exposed by the engine and how users can interact with them to execute actions, retrieve a history of state changes or commands, listen to event streams...

## Pre-requisites
Follow the configuration steps detailed in `README.md` and make sure you can run the components detailed therein.

## Context
The NPL code base in the `npl-integrations` application builds on the IoU example of the [npl-starter](https://github.com/NoumenaDigital/npl-starter) repository, adding a `RepaymentOccurrence` notification triggered when the IoU issuer calls the `pay`action to claim she/he has repaid an amount on the IoU, a permission `confirmPayment` that can be invoked by the payee to confirm such a repayment did indeed happen, and a new state `payment_confirmation_required` to reflect that after each `pay` invocation a confirmation is now required. The python listener service is designed to pick up `paymentOccurence` notifications and "call back" to confirm repayments. For simplicity, that python listener service authenticates as one specific user among the provisioned ones, namely Bob, meaning that the listener will only callback to confirm payments with success on IoU's where Bob (identified as bob@noumenadigital.com in the IoU creation form in the frontend) is the payee. The new state and the new state transitions can be visualized in the State Machine Analyzer provided by the NPL Dev Plugin.

## Part 1: Local deployment of engine and keycloak
**Step 1:** Deploy the NPL in an engine running locally, using docker:
```shell
$ docker compose up -d --build engine keycloak-provisioning
```

Notes:
- The `--build` flag in docker compose ensures that if containers are recreated, images are rebuilt first from the latest sources. 
- Look at the deployed containers using the Docker Desktop app or typing `docker ps -a`. You should see the engine and its database running, as well as keycloak and its database.
- Keycloak has been provisioned with users Alice, Bob and Eve. A container `keycloak-provisioning` should show up as exited among docker containers since provisioning has completed. For technical details on the provisioning, follow the trail from the `keycloak-provisioning` service in `docker-compose.yml` to script `local.sh` and terraform file `terraform.tf` in module `keycloak-provisioning`.
- Open the keycloak administration console accessible under `http://keycloak:11000/admin/master/console/` (also via `http://keycloak:11000`)


## Dump of remainder

E. Open Keycloak console, show users provisioned
F. Open Engine API, append swagger-ui/, generated API, test interaction listing IoUs

2. Get Alice JWT

```shell
$ curl -s 'http://localhost:11000/realms/nplintegrations/protocol/openid-connect/token' \
   -d 'username=alice' \
   -d 'password=alice' \
   -d 'grant_type=password' \
   -d 'client_id=nplintegrations' \
   | jq -j .access_token
```

G. Retest ListIoUs after authentication, success
H. Create IoU with postman, re-list on engine API
[Add: now can list what actions you have access to bet GETTING one instance]
I. Other APIs we have been discussing on the graph earlier, e.g. streaming API

3.  Event stream

```shell
$ TOKEN=$(curl -s 'http://localhost:11000/realms/nplintegrations/protocol/openid-connect/token' -d 'username=alice' -d 'password=alice' -d 'grant_type=password' -d 'client_id=nplintegrations' | jq -j .access_token) \
&& curl 'http://localhost:12000/api/streams' -H "Authorization: Bearer ${TOKEN}" -H 'Accept: text/event-stream'
```

J. Repay part of IoU as Alice, see events on console with stream (command and state)
K. Comment on state change linking to command, and command linking to agent/keycloak user Id = auditability
L. We can replay state history and command history for audit

4. State history

```shell
$ TOKEN=$(curl -s 'http://localhost:11000/realms/nplintegrations/protocol/openid-connect/token' -d 'username=alice' -d 'password=alice' -d 'grant_type=password' -d 'client_id=nplintegrations' | jq -j .access_token) \
&& curl 'http://localhost:12000/api/streams/current-archived-states' -H "Authorization: Bearer ${TOKEN}" -H 'Accept: text/event-stream'
```

5. Command history
```shell
$ TOKEN=$(curl -s 'http://localhost:11000/realms/nplintegrations/protocol/openid-connect/token' -d 'username=alice' -d 'password=alice' -d 'grant_type=password' -d 'client_id=nplintegrations' | jq -j .access_token) \
&& curl 'http://localhost:12000/api/streams/current-commands' -H "Authorization: Bearer ${TOKEN}" -H 'Accept: text/event-stream'
```

M. Streaming/history are permissioned, create Bob-Alice IoU and Bob-Charlie IoU, check in Alice's streams/history
N. How easy is it to adjust and redeploy a fully functional app? Uncomment doSomething() lines, redeploy in 5 seconds

6. Deploy adjusted NPL
```shell
$ docker compose down -v && docker compose up -d --build engine keycloak-provisioning
```

O. Similarly, we would deploy to cloud or what we call PaaS. Let's now look at more complete application, show slide, point to python and webapp modules, show streams in main.py and HomePage.tsx
P. Can build on generated API clients for faster development & ensure integration breaking changes are revealed at compile time, point to generated folders, show some model in api.ts
Q. Delete generated folder, regenerate in 5-10 seconds with:

7. Generate API clients
```shell
$ mvn clean install
```

8. Deploy with Python & WebApp
   #docker compose down -v && docker compose up --wait
```shell
$ docker compose down -v && docker compose up --build --wait engine keycloak-provisioning webapp python-service
```

R. Show services in docker desktop, comment on webapp, python, read model; show python logs
S. Open webapp, create Alice-Bob IoU, log in as Bob, log in as Alice, repay IoU, comment on state update, show python logs in docker desktop
T. Let's now look at other deployment scenario, PaaS + local, show PaaS slide
U. Log into PaaS with Microsoft Azure account (browser bookmark, https://portal.noumena.cloud/training), explain tenant, app, show previously uploaded app, Keycloak; open swagger UI and NPL generated API, does not yet have doSomething(), let's redeploy

9. Login & Deploy to PaaS 

```shell
$ az login
```
```shell
$ make clear-deploy
```

V. Show updated app (date, swagger UI)

10. Build & Run standalone Python
    (cd python-listener && mkdir -p venv && python3 -m venv venv && source venv/bin/activate)
```shell
$ pip install -r requirements.txt && python3 app.py
```

W. Show console output and comment on PaaS Keycloak URL & engine URL

11. Build & Run standalone WebApp
    (cd webapp)
```shell
$ npm install && npm run dev
```

X. Open Webapp, login as Alice, create IoU, repay; show python log in console; show updated state in UI

Additions: Get JWT token from PaaS Keycloak [adjust url and client_id if app name has changed from sparc to something else]
\    
curl -s 'https://keycloak-training-nplintegrations2.noumena.cloud/realms/nplintegrations2/protocol/openid-connect/token' \
-d 'username=alice' \
-d 'password=alice' \
-d 'grant_type=password' \
-d 'client_id=sparc' \
| jq -j .access_token
