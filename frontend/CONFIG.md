# Configuration

## AUTH

Defined by LOGIN_MODE environment variable.

- DEV MODE:
    - uses custom login form with /token endpoint
- CUSTOM OIDC LOGIN
    - uses custom login form with /protocol/openid-connect/token endpoint
- KEYCLOAK
    - uses keycloak lib

## API

Defined by DEPLOYMENT_TARGET environment variable.

- LOCAL:
    - NPL Engine running in docker running locally
- NOUMENA CLOUD:
    - NPL Engine running on NOUMENA CLOUD

## Combinations

1. dev mode: LOCAL + DEV MODE
2. local user management: LOCAL + CUSTOM OIDC LOGIN
3. complete user management, prepare for cloud deployment: LOCAL + KEYCLOAK
4. cloud deployment: NOUMENA CLOUD + KEYCLOAK
