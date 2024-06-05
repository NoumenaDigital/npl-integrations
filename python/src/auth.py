import time
import requests
from src import config


class AuthService:

    def __init__(self):
        super().__init__()
        self.validity = time.time() - 1
        self.access_token = None

    def auth(self, usr: str, pwd: str):
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

        json_response = response.json()
        self.access_token = json_response["access_token"]
        self.validity = time.time() + int(json_response["expires_in"])
        return json_response["access_token"]

    def get_access_token(self):
        if self.validity < time.time():
            self.auth(config.USERNAME, config.PASSWORD)
        return self.access_token
