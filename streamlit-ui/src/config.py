import os

ORG = os.getenv("ORG") if os.getenv("ORG") is not None else "training"
REALM = os.getenv("REALM") if os.getenv("REALM") is not None else "nplintegrations"

NOUMENA_DOMAIN = f"{ORG}-{REALM}.noumena.cloud"
KEYCLOAK_DOMAIN = f"keycloak-{NOUMENA_DOMAIN}"
PAAS_TOKEN_URL = f"https://{KEYCLOAK_DOMAIN}/realms/{REALM}/protocol/openid-connect/token"
PAAS_USER_INFO_URL = f"https://{KEYCLOAK_DOMAIN}/realms/{REALM}/protocol/openid-connect/userinfo"
PAAS_ROOT_URL = f"https://engine-{NOUMENA_DOMAIN}"

LOCAL_TOKEN_URL = f"""http://keycloak:11000/realms/{REALM}/protocol/openid-connect/token"""
LOCAL_USER_INFO_URL = f"""http://keycloak:11000/realms/{REALM}/protocol/openid-connect/userinfo"""
LOCAL_ROOT_URL = "http://engine:12000"

local = os.getenv("ENV") == "LOCAL"
TOKEN_URL = LOCAL_TOKEN_URL if local else PAAS_TOKEN_URL
ROOT_URL = LOCAL_ROOT_URL if local else PAAS_ROOT_URL
USER_INFO_URL = LOCAL_USER_INFO_URL if local else PAAS_USER_INFO_URL

USERNAME = "bob"
PASSWORD = "bob"
