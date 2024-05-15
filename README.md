# npl-integrations

## Python

The './python' folder contains a python service interacting with the configured engine.

### Setup

1. set up & activate your Python venv
2. run `mvn install` to generate the python client
3. run `cd python && pip install -r requirements.txt` 

### Running

run `cd python && python main.py`

## Webapp

The './webapp' folder contains a typescript frontend service interacting with the configured engine.

### Setup

1. run `mvn install` to generate the webapp client (if not already done for python)
2. run `cd webapp && npm install`

### Running

run `cd webapp && npm run dev`
