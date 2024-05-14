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
        url=config.TOKEN_URL,
        data=data
    )
    response.raise_for_status()

    return response.json()["access_token"]

