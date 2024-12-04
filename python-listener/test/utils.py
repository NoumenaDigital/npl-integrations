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
