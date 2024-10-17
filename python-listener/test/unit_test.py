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


def setup_notification_mock(notification_mock, notifications):
    notification_mock.return_value.__enter__.return_value = iter([
        MessageEvent(
            type=notification_type,
            data=notification_data,
            origin="my origin",
            last_event_id="my last_event_id"
        ) for (notification_type, notification_data) in notifications
    ])


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


@patch('src.stream.StreamReader.get_stream')
def test_stream_events(mock_get_stream):
    notifications = [
        ("notify", '{"x": 1}'),
        ("state", '{"z": 3}')
    ]
    setup_notification_mock(mock_get_stream, notifications)

    stream_reader = StreamReader(None)
    count = 0
    for i, event in enumerate(stream_reader.read_stream("")):
        assert_equal(event, json.loads(notifications[i][1]))
        count += 1
    assert_equal(len(notifications), count)


@patch('src.stream.StreamReader.get_stream')
def test_stream_pass(mock_get_stream):
    event_types = [
        "tick",
        "command",
        "something else"
    ]
    mock_get_stream.return_value.__enter__.return_value = iter([
        MessageEvent(
            type=et,
            data="not processed",
            origin="my origin",
            last_event_id="my last_event_id"
        ) for et in event_types
    ])

    stream_reader = StreamReader(None)
    count = 0
    for _ in stream_reader.read_stream(""):
        count += 1
    assert_equal(0, count)


@patch('src.stream.StreamReader.manage_repayment_occurrence')
@patch('src.stream.StreamReader.get_stream')
@patch('src.auth.requests.post')
def test_main(mock_auth, mock_get_stream, mock_manage_repayment_occurrence):
    setup_auth_mock(mock_auth)

    notification = Notification(
        type='notification',
        refId='iou1234uuid',
        protocolVersion='1',
        agents=[],
        created='2021-01-01T00:00:00Z',
        name=REPAYMENT_OCCURRENCE_NAME,
        arguments=[
            {"nplType": "number", "value": 10},
            {"nplType": "number", "value": 5}
        ],
        callback='https://dosomething.com'
    )

    setup_notification_mock(
        mock_get_stream,
        [
            ("notify", json.dumps({
                "notification": {
                    k: [arg.__dict__ for arg in v]
                    if (k == "arguments") else v for k, v
                    in notification.__dict__.items()
                }
            }))
        ]
    )

    app.main()

    mock_manage_repayment_occurrence.assert_called_with(notification)
