from nose.tools import assert_is_not_none, assert_equal
from unittest.mock import patch

from src.auth import AuthService


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
