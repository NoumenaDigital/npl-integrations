
import streamlit as st

from src import iou
from src import config

from openapi_client.api.default_api import DefaultApi
from openapi_client.api_client import ApiClient
from openapi_client.configuration import Configuration

@st.cache_resource
def get_api():
    api = DefaultApi(
        ApiClient(
            Configuration(
                access_token=st.session_state['access_token'],
                host=config.ROOT_URL,
                api_key={},
                api_key_prefix={}
            )
        )
    )
    return api

def createIou():
    import streamlit as st

    with st.form("new_iou_form"):
        st.write("Create an IOU")
        description_val = st.text_input("Description")
        amount_val = st.number_input("Iou amount")

        # Every form must have a submit button.
        submitted = st.form_submit_button("Submit")
        if submitted:
            try:
                created_iou = iou.create_iou(get_api(), description_val, amount_val, "bob@noumenadigital.com", "alice@noumenadigital.com")
                st.write("Iou created:", str(created_iou))
            except Exception as e:
                st.write(f"Error: {e}")

def listIou():
    import streamlit as st
    import pandas as pd

    iou_list = get_api().get_iou_list()
    iou_df = pd.DataFrame([[iou.description, iou.for_amount] for iou in iou_list.items], columns=["Description", "Amount"])
    st.write("IOU List")
    st.write(iou_df)

def app_page():
    import streamlit as st
    
    page_names_to_funcs = {
        "Create IOU": createIou,
        "IOU List": listIou,
    }

    demo_name = st.sidebar.selectbox("Choose a demo", page_names_to_funcs.keys())
    page_names_to_funcs[demo_name]()