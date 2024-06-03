import time
import requests
from src import config

class AuthService:

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

        jsonResponse = response.json()
        self.access_token = jsonResponse["access_token"]
        self.validity = time.time() + int(jsonResponse["expires_in"])
        return jsonResponse["access_token"]
    
    def get_access_token(self):
        if self.validity < time.time():
            self.auth(config.USERNAME, config.PASSWORD)
        return self.access_token


