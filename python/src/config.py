import os

ORG = os.getenv("ORG") if os.getenv("ORG") is not None else "training"
REALM = os.getenv("REALM") if os.getenv("REALM") is not None else "nplintegrations"
LOCAL_TOKEN_URL = f"""http://keycloak:11000/realms/{REALM}/protocol/openid-connect/token"""
LOCAL_ROOT_URL = "http://engine:12000"
PAAS_TOKEN_URL = f"""https://keycloak-{ORG}-{REALM}.noumena.cloud/realms/{REALM}/protocol/openid-connect/token"""
PAAS_ROOT_URL = f"""https://engine-{ORG}-{REALM}.noumena.cloud"""
USERNAME = "bob"
PASSWORD = "bob"
