import json
import time

from nose.tools import assert_is_not_none, assert_equal, assert_true
from unittest.mock import patch
from requests_sse import MessageEvent

import app
from src.auth import AuthService
from src.stream import Notification, REPAYMENT_OCCURRENCE_NAME, StreamReader
from test.utils import setup_auth_mock


@patch('src.auth.requests.post')
def test_auth(mock_auth):
    my_access_token = setup_auth_mock(mock_auth)

    my_username = 'my_username'
    my_password = 'my_password'
    auth_service = AuthService()

    access_token = auth_service.auth(
        my_username,
        my_password
    )

    assert_is_not_none(access_token)
    assert_equal(access_token, my_access_token)
    assert_true(auth_service.validity > time.time() + 3600 - 10 - 5)
