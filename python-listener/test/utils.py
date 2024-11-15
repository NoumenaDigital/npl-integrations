import json
import time

from nose.tools import assert_is_not_none, assert_equal, assert_true
from unittest.mock import patch
from requests_sse import MessageEvent

import app
from src.auth import AuthService
from src.stream import Notification, REPAYMENT_OCCURRENCE_NAME, StreamReader


def raise_for_status():
    pass


def setup_auth_mock(mock_auth):
    my_access_token = "my_access_token"

    def json_fct():
        return {
            "access_token": my_access_token,
            "expires_in": 3600
        }

    mock_auth.return_value.raise_for_status = raise_for_status
    mock_auth.return_value.json = json_fct
    return my_access_token
