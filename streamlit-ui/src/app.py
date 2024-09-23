import base64
import mimetypes

import jwt

import pandas as pd
import streamlit as st

from openapi_client.models.iou_add_file_command import IouAddFileCommand

from src import iou
from src import config

from openapi_client.api.default_api import DefaultApi
from openapi_client.api_client import ApiClient
from openapi_client.configuration import Configuration

if "uploader_key" not in st.session_state:
    st.session_state.uploader_key = 0

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
                decoded_token = jwt.decode(st.session_state['access_token'], algorithms=["RS256"], key=None, options={"verify_signature":False})
                created_iou = iou.create_iou(get_api(), description_val, amount_val, recipient, str(decoded_token['email']))
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
        iou_i.description,
        iou_i.for_amount,
        iou_i.amount_owed,
        iou_i.parties.issuer.entity["email"][0],
        iou_i.parties.payee.entity["email"][0]
        ] for iou_i in iou_list.items], columns=["Description", "Total amount", "Owed amount", "Issuer", "Payee"])
    st.write("IOU List")
    st.write(iou_df)


def print_iou(iou_to_print):
    return f"{iou_to_print.id} - {iou_to_print.description}"


def iou_select():
    iou_list = get_api().get_iou_list().items
    selected_iou = st.selectbox("Select IOU", iou_list, format_func=print_iou) # [iou_i.id for iou_i in iou_list.items])
    st.session_state["selected_iou"] = selected_iou.id
    iou_details()


def iou_details():
    iou_id = st.session_state["selected_iou"]

    if iou_id is not None and iou_id != "":
        selected_iou = get_api().get_iou_by_id(iou_id)
        st.write("Iou created:")
        st.write("ID:", selected_iou.id)
        st.write("State:", str(selected_iou.state))
        st.write("Description:", selected_iou.description)
        st.write("Total amount:", selected_iou.for_amount)
        st.write("Owed amount:", selected_iou.amount_owed)
        st.write("Issuer:", selected_iou.parties.issuer)
        st.write("Payee:", selected_iou.parties.payee)

        uploaded_file = st.file_uploader("Upload file here", key=f"uploader_{st.session_state.uploader_key}")

        if uploaded_file is not None:
            bytes_data = uploaded_file.getvalue()
            encoded_bytes_data = base64.b64encode(bytes_data).decode('utf-8')

            mimetype = mimetypes.guess_type(uploaded_file.name)[0]
            file = f"data:{mimetype};filename={uploaded_file.name};base64,{encoded_bytes_data}"
            get_api().iou_add_file(iou_id, IouAddFileCommand(file=file))
            st.session_state.uploader_key += 1
            st.rerun()

        for i, f in enumerate(selected_iou.files):
            file = f.split(";")

            if len(file) == 3:
                filename = file[1].split("=")[1]
                st.write("File name:", filename)
            else:
                filename = None
                st.write("File:")

            file_data = file[-1].split(",")
            if file_data[0] == "base64":
                file_bytes = base64.b64decode(file_data[1])
            else:
                file_bytes = file_data[1].encode('utf-8')
            filetype = file[0].split(":")[1]
            if "image" in filetype:
                st.image(file_bytes)
            else:
                st.write(file_bytes)
            st.download_button(
                label='Download file',
                data=file_bytes,
                file_name=filename,
                mime=filetype,
                key=i,
            )

def app_page():
    page_names_to_funcs = {
        "Create IOU": create_iou,
        "IOU List": list_iou,
        "IOU Details": iou_select,
    }

    demo_name = st.sidebar.selectbox("Choose a demo", page_names_to_funcs.keys())
    page_names_to_funcs[demo_name]()
