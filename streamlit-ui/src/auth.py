import requests

import streamlit as st

from src import config


def get_token(username, password):
    token_data = {
        'grant_type': 'password',
        'client_id': config.REALM,
        'username': username,
        'password': password,
        'scope': 'openid',
    }

    response = requests.post(config.TOKEN_URL, data=token_data)
    response.raise_for_status()
    return response.json()


def get_user_info(access_token):
    headers = {
        'Authorization': f'Bearer {access_token}',
    }
    response = requests.get(config.USER_INFO_URL, headers=headers)
    response.raise_for_status()
    return response.json()


def login_page():
    st.title("Login")

    username = st.text_input("Username")
    password = st.text_input("Password", type="password")

    if st.button("Login"):
        if username and password:
            try:
                token_response = get_token(username, password)
                access_token = token_response['access_token']
                user_info = get_user_info(access_token)

                st.success("You are logged in!")

                st.session_state['logged_in'] = True
                st.session_state['user_info'] = user_info
                st.session_state['access_token'] = access_token
                st.rerun()
            except requests.exceptions.HTTPError as e:
                st.error(f"Login failed: {e}")
        else:
            st.error("Please enter both username and password.")
