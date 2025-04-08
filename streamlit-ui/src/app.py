import jwt

import pandas as pd
import streamlit as st

from src import iou
from src import config

from iou.api.default_api import DefaultApi
from iou.api_client import ApiClient
from iou.configuration import Configuration


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


def create_iou():
    with st.form("new_iou_form"):
        st.write("Create an IOU")
        description_val = st.text_input("Description")
        amount_val = st.number_input("Iou amount")
        recipient = st.text_input("Recipient email")

        submitted = st.form_submit_button("Submit")
        if submitted:
            try:
                decoded_token = jwt.decode(
                    st.session_state['access_token'],
                    algorithms=["RS256"],
                    key=None,
                    options={"verify_signature": False}
                )
                created_iou = iou.create_iou(
                    api=get_api(),
                    description=description_val,
                    amount=amount_val,
                    issuer=str(decoded_token['email']),
                    payee=recipient
                )
                st.write("Iou created:")
                st.write("ID:", created_iou.id)
                st.write("State:", str(created_iou.state))
                st.write("Description:", created_iou.description)
                st.write("Total amount:", created_iou.for_amount)
                st.write("Owed amount:", created_iou.amount_owed)
                st.write("Issuer:", created_iou.parties.issuer)
                st.write("Payee:", created_iou.parties.payee)
            except Exception as e:
                st.write(f"Error: {e}")


def list_iou():
    iou_list = get_api().get_iou_list()
    iou_df = pd.DataFrame([[
        iou.description,
        iou.for_amount,
        iou.amount_owed,
        iou.parties.issuer.entity["email"][0],
        iou.parties.payee.entity["email"][0]
        ] for iou in iou_list.items], columns=["Description", "Total amount", "Owed amount", "Issuer", "Payee"])
    st.write("IOU List")
    st.write(iou_df)


def app_page():
    page_names_to_funcs = {
        "Create IOU": create_iou,
        "IOU List": list_iou,
    }

    demo_name = st.sidebar.selectbox("Choose a demo", page_names_to_funcs.keys())
    page_names_to_funcs[demo_name]()
