import os

ORG = os.getenv("ORG") if os.getenv("ORG") is not None else "pwctraining"
REALM = os.getenv("REALM") if os.getenv("REALM") is not None else "vwfs"
NOUMENA_DOMAIN = f"{ORG}-{REALM}.noumena.cloud"
KEYCLOAK_DOMAIN = f"keycloak-{NOUMENA_DOMAIN}"
TOKEN_URL = f"https://{KEYCLOAK_DOMAIN}/realms/{REALM}/protocol/openid-connect/token"
USER_INFO_URL = f"https://{KEYCLOAK_DOMAIN}/realms/{REALM}/protocol/openid-connect/userinfo"
ROOT_URL = f"https://engine-{NOUMENA_DOMAIN}"
