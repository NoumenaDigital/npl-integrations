from src import auth
from src import config
from src import stream

from openapi_client.api.default_api import DefaultApi
from openapi_client.api_client import ApiClient
from openapi_client.configuration import Configuration

if __name__ == '__main__':
    access_token = auth.auth(
        config.USERNAME,
        config.PASSWORD
    )

    if access_token == "":
        print("error during login")
        exit
    else:
        print("login succeeded")

    api = DefaultApi(
        ApiClient(
            Configuration(
                access_token=access_token,
                host=config.ROOT_URL,
                api_key={},
                api_key_prefix={},
                username=config.USERNAME,
                password=config.PASSWORD,
            )
        )
    )

    streamReader = stream.StreamReader(api)
    for event in streamReader.readStream(access_token):
        streamReader.manageNotification(event)
