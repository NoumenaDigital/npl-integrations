# npl-integrations

## Python

The './python' folder contains a python service interacting with the configured engine.

### Setup

1. set up & activate your Python venv
2. run `mvn install` to generate the python client
3. run `cd python && pip install -r requirements.txt` 

Note: it is needed to install requirements every time NPL code is changed.
This is because the generated code is installed as a package for easier use.

### Running

run `cd python && python main.py`

and in another terminal

run `cd python && python notification.py`

## Webapp

The './webapp' folder contains a typescript frontend service interacting with the configured engine.

### Setup

1. run `mvn install` to generate the webapp client (if not already done for python)
2. run `cd webapp && npm install`

### Running

run `cd webapp && npm run dev`
