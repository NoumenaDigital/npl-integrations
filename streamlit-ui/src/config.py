import os
from dotenv import load_dotenv

load_dotenv("../.env")
load_dotenv()

ORG = os.getenv("VITE_NC_ORG_NAME") if os.getenv("VITE_NC_ORG_NAME") is not None else "training"
REALM = os.getenv("VITE_NC_APP_NAME") if os.getenv("VITE_NC_APP_NAME") is not None else "nplintegrations"
NOUMENA_DOMAIN = f"{ORG}-{REALM}.noumena.cloud"
KEYCLOAK_DOMAIN = f"keycloak-{NOUMENA_DOMAIN}"
TOKEN_URL = f"https://{KEYCLOAK_DOMAIN}/realms/{REALM}/protocol/openid-connect/token"
USER_INFO_URL = f"https://{KEYCLOAK_DOMAIN}/realms/{REALM}/protocol/openid-connect/userinfo"
ROOT_URL = f"https://engine-{NOUMENA_DOMAIN}"
