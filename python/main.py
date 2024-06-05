from src.auth import AuthService
from src import config
from src import stream

from openapi_client.api.default_api import DefaultApi
from openapi_client.api_client import ApiClient
from openapi_client.configuration import Configuration

if __name__ == '__main__':
    authService = AuthService()

    access_token = authService.auth(
        config.USERNAME,
        config.PASSWORD
    )

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

    streamReader = stream.StreamReader(api, "/api/streams")
    for event in streamReader.read_stream(access_token):
        
        api.api_client.configuration.access_token = authService.get_access_token()

        if "payload" in event:
            streamReader.manage_state_change(event["payload"])
        else:
            print("Unrecognised stream event", event)
