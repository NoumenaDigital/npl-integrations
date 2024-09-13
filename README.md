# npl-integrations

The npl-integrations repo contains a sample project that demonstrates how to integrate with the NPL engine using
different programming languages and frameworks.
It includes a Python client, a webapp, and a streamlit UI.

The underlying NPL code is an extension of the IOU, which can be found
in the [npl-starter](https://github.com/NoumenaDigital/npl-starter) repository.

## Building and running with docker locally

### Pre-requisites

For OS X and linux systems, make sure the `/etc/hosts` file includes the line `127.0.0.1 keycloak`

![img.png](docs/img.png)

If not

1. Use the `sudo nano /etc/hosts` command to open the file in a text editor.
2. Navigate to the end of the file and add the line `127.0.0.1 keycloak`.
3. Save by pressing `Ctrl + O` and then `Enter`.

### Build & run

To build and run the project, follow the steps below:

1. Run `mvn clean install` to build and generate NPL-api and clients.
2. Run `docker compose up --build -d` to ensure python and frontend are also build, then create and start containers.

### Service endpoints

Once the project is running, services run behind the following URLs:

| Service                   | URL                                |
|---------------------------|------------------------------------|
| Engine APIs               | http://localhost:12000/            |
| Swagger UI of Engine APIs | http://localhost:12000/swagger-ui/ |
| Keycloak admin console    | http://localhost:11000             |
| Webapp                    | http://localhost:8090              |
| Inspector                 | http://localhost:8070              |

## Building, running python & webapp locally, NPL on PaaS

### NPL and keyloack

#### Option 1: Using the NPL CLI & terraform

1. Install the NPL CLI by running `make download-cli` in the root directory.
2. Add the following variables to your shell to configure the NPL CLI and restart your terminal

    ```
    export NC_BASE_URL=https://portal.noumena.cloud
    export NC_EMAIL=your.email@your.domain
    export NC_ENV=PROD
    ```

3. Run `make create-app` to create the application with name defined in Makefile.
4. Run `make iam` to provision keycloak on the created PaaS application with terraform.
5. Run `make clear-deploy` to clear pre-existing packages in the app and upload current NPL and migration sources.

#### Option 2: Using the maven plugin

1. Edit run configurations by clicking on the three vertical dots icon at the top right of IntelliJ
2. Add a new configuration by clicking on the `+` icon and selecting `Deploy to PaaS`
3. Input the following values:
    - `Server base URL`: https://portal.noumena.cloud
    - `Application ID`: The application ID found on the settings page of your app in PaaS UI
    - `Username`: Your email address for PaaS
    - `Password`: Your password for PaaS
    - `Source path`: Use the file navigator to navigate to `./npl/src/main` inside the project

4. Click `Run` to save and run the configuration

In addition, Keycloak can be configured from the `Services` tab in the PaaS UI.

#### Option 3: Using the PaaS UI

1. Create a zip file by running the `zip -r sources.zip npl/src/main/` command in the root directory.
2. In PaaS UI, click on `Upload packages` and upload the zip file.

### Python

The `./python` folder contains a python service interacting with the configured engine.

#### Setup

1. set up & activate your Python venv
2. run `mvn install` to generate the python client
3. run `cd python && pip install -r requirements.txt`

Note: it is needed to install requirements every time NPL code is changed.
This is because the generated code is installed as a package for easier use.

#### Running

run `cd python && python main.py`

### Webapp

The `./webapp` folder contains a typescript frontend service interacting with the configured engine.

#### Setup

1. run `mvn install` to generate the webapp client (if not already done for python)
2. run `cd webapp && npm install`

#### Running

run `cd webapp && npm run dev`

### Streamlit UI

The `./streamlit-ui` folder contains a frontend implemented in python with the streamlit library.
It connects to the engine and displays entries of the engine database.

#### Setup

1. set up & activate your Python venv
2. run `mvn install` to generate the python client
3. run `cd streamlit-ui && pip install -r requirements.txt`

Note: it is needed to install requirements every time NPL code is changed.
This is because the generated code is installed as a package for easier use.

#### Running

run `cd streamlit-ui && streamlit run main.py`

### Service endpoints

Once the project is running, services run behind the following URLs:

| Service                   | URL                                                                  |
|---------------------------|----------------------------------------------------------------------|
| Engine APIs               | `https://engine-$NC_ORG_NAME-$NC_APP_NAME.noumena.cloud`             |
| Swagger UI of Engine APIs | `https://engine-$NC_ORG_NAME-$NC_APP_NAME.noumena.cloud/swagger-ui/` |
| Keycloak admin console    | `https://keycloak-$NC_ORG_NAME-$NC_APP_NAME.noumena.cloud`           |
| Webapp                    | http://localhost:5173                                                |

## Next steps

You can now start developing your own application on top of the NPL engine in your preferred language.

For more information on the NPL engine, please refer to
the [NPL documentation](https://documentation.noumenadigital.com/). 
