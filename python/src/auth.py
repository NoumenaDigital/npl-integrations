import requests
from src import config

def auth(usr: str, pwd: str):
    data = {
        "username": usr,
        "password": pwd,
        "client_id": config.REALM,
        "grant_type": "password"
    }
    response = requests.post(
        url=config.IDENTITY_URL + "/realms/" + config.REALM + "/protocol/openid-connect/token",
        data=data
    ).json()

    if ("access_token" not in response):
        print("error", response, data)
        return
    return response["access_token"]
