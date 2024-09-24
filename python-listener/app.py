from main.src.auth import AuthService
from main.src import config, stream

from openapi_client.api.default_api import DefaultApi
from openapi_client.api_client import ApiClient
from openapi_client.configuration import Configuration

if __name__ == '__main__':
    auth_service = AuthService()

    access_token = auth_service.auth(
        config.USERNAME,
        config.PASSWORD
    )

    print(f"{config.USERNAME} login succeeded")

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

    stream_reader = stream.StreamReader(api)
    for event in stream_reader.read_stream(access_token):
        api.api_client.configuration.access_token = auth_service.get_access_token()

        if "payload" in event:
            stream_reader.manage_state_change(event["payload"])
        elif "notification" in event:
            stream_reader.manage_notification(event["notification"])
        else:
            print("Unrecognised stream event", event)
