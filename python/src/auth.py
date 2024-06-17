import os
import requests
from src import config

def auth(usr: str, pwd: str):
    data = {
        "username": usr,
        "password": pwd,
        "client_id": config.REALM,
        "grant_type": "password"
    }
    url = config.LOCAL_TOKEN_URL if os.getenv("ENV") == "LOCAL" else config.PAAS_TOKEN_URL
    print("auth url ", url)
    response = requests.post(
        url=url,
        data=data
    )
    response.raise_for_status()

    return response.json()["access_token"]

