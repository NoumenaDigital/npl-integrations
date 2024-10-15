from nose.tools import assert_is_not_none, assert_equal
from unittest.mock import patch, MagicMock
from unittest import mock

from requests_sse import MessageEvent

from src.auth import AuthService
from src import stream


def raise_for_status():
    pass


@patch('src.auth.requests.post')
def test_auth(mock_post):
    my_access_token = "my_access_token"

    def json_fct():
        return {
            "access_token": my_access_token,
            "expires_in": 3600
        }
    mock_post.return_value.raise_for_status = raise_for_status
    mock_post.return_value.json = json_fct

    my_username = 'my_username'
    my_password = 'my_password'
    auth_service = AuthService()

    access_token = auth_service.auth(
        my_username,
        my_password
    )

    assert_is_not_none(access_token)
    assert_equal(access_token, my_access_token)

# @patch('src.stream.StreamReader.get_stream')
def test_stream(): # mock_get

    stream_reader = stream.StreamReader(None)

    with mock.patch('src.stream.StreamReader.get_stream') as mock_f:
        mock_f.return_value.__enter__.return_value = iter([
            MessageEvent(
                type="notify",
                data='{"x": 1}',
                origin="my origin",
                last_event_id="my last_event_id"
            ),
            2,
            3
        ])

        for event in stream_reader.read_stream(""):
            print(event)
            assert_equal(event, "not likely to be this")
        assert_equal(1, 1)
