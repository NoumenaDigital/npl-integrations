import os
from dotenv import load_dotenv

load_dotenv("../.env")
load_dotenv()

ORG = os.getenv("VITE_NC_ORG_NAME") if os.getenv("VITE_NC_ORG_NAME") is not None else "training"
REALM = os.getenv("VITE_NC_APP_NAME") if os.getenv("VITE_NC_APP_NAME") is not None else "nplintegrations"
DOMAIN = os.getenv("DOMAIN") if os.getenv("DOMAIN") is not None else "noumena.cloud"
LOCAL_TOKEN_URL = f"""http://keycloak:11000/realms/{REALM}/protocol/openid-connect/token"""
LOCAL_ROOT_URL = "http://engine:12000"
LOCAL_USER_INFO_URL = f"""http://keycloak:11000/realms/{REALM}/protocol/openid-connect/userinfo"""
CLOUD_TOKEN_URL = f"""https://keycloak-{ORG}-{REALM}.{DOMAIN}/realms/{REALM}/protocol/openid-connect/token"""
CLOUD_ROOT_URL = f"""https://engine-{ORG}-{REALM}.{DOMAIN}"""
CLOUD_USER_INFO_URL = f"""https://keycloak-{ORG}-{REALM}.{DOMAIN}/realms/{REALM}/protocol/openid-connect/userinfo"""

local = os.getenv("ENV") == "LOCAL"
TOKEN_URL = LOCAL_TOKEN_URL if local else CLOUD_TOKEN_URL
USER_INFO_URL = LOCAL_USER_INFO_URL if local else CLOUD_USER_INFO_URL
ROOT_URL = LOCAL_ROOT_URL if local else CLOUD_ROOT_URL
