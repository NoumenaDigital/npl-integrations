import streamlit as st

from src import auth
from src import app


def main_page():
    st.title("Main Application")

    if 'user_info' in st.session_state:
        st.write("Welcome, ", st.session_state['user_info']['preferred_username'])
        st.write("User Info:", st.session_state['user_info'])

        if st.button("Logout"):
            st.session_state.clear()
            st.rerun()
    else:
        st.warning("You are not logged in.")
        st.rerun()


def main():
    if 'logged_in' not in st.session_state:
        st.session_state['logged_in'] = False

    if st.session_state['logged_in']:
        app.app_page()
    else:
        auth.login_page()


if __name__ == "__main__":
    main()
