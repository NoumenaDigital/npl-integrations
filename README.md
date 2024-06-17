# npl-integrations

## Building and running with docker locally

1. Run `mvn clean install` to build and generate NPL-api and clients.
2. Run `docker compose up --wait` to create and start containers.

URLs:
* Swagger UI of Engine APIs: http://localhost:12000/swagger-ui/
* Keycloak admin console: http://localhost:11000
* Webapp: http://localhost:8080

## Building, running python & webapp locally, NPL on PaaS

### Python

The './python' folder contains a python service interacting with the configured engine.

#### Setup

1. set up & activate your Python venv
2. run `mvn install` to generate the python client
3. run `cd python && pip install -r requirements.txt` 

#### Running

run `cd python && python main.py`

### Webapp

The './webapp' folder contains a typescript frontend service interacting with the configured engine.

#### Setup

1. run `mvn install` to generate the webapp client (if not already done for python)
2. run `cd webapp && npm install`

#### Running

run `cd webapp && npm run dev`
