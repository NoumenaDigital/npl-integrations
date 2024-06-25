# npl-integrations

## Building and running with docker locally

1. Run `mvn clean install` to build and generate NPL-api and clients.
2. Run `docker compose up --build -d` to ensure python and frontend are also build, then create and start containers.

URLs:
* Swagger UI of Engine APIs: http://localhost:12000/swagger-ui/
* Keycloak admin console: http://localhost:11000
* Webapp: http://localhost:8080

## Building, running python & webapp locally, NPL on PaaS

### NPL and keyloack

1. Add the following variables to your shell
```
export NC_BASE_URL=https://portal.noumena.cloud
export NC_EMAIL=your.email@your.domain
export NC_ENV=PROD
```
2. Run `make create-app` to create the application with name defined in Makefile.
3. Run `make iam` to provision keycloak on the created PaaS application with terraform.
4. Run `make clear-deploy` to clear pre-existing packages in the app and upload current NPL and migration sources.

### Python

The './python' folder contains a python service interacting with the configured engine.

#### Setup

1. set up & activate your Python venv
2. run `mvn install` to generate the python client
3. run `cd python && pip install -r requirements.txt` 

Note: it is needed to install requirements every time NPL code is changed.
This is because the generated code is installed as a package for easier use.

#### Running

run `cd python && python main.py`

and in another terminal

run `cd python && python notification.py`

### Webapp

The './webapp' folder contains a typescript frontend service interacting with the configured engine.

#### Setup

1. run `mvn install` to generate the webapp client (if not already done for python)
2. run `cd webapp && npm install`

#### Running

run `cd webapp && npm run dev`
