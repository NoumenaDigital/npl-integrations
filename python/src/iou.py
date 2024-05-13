from openapi_client.api.default_api import DefaultApi
from openapi_client.models.iou_create import IouCreate
from openapi_client.models.iou_parties import IouParties
from openapi_client.models.party import Party
from openapi_client.exceptions import NotFoundException

def createIou(api: DefaultApi):
    try:
        return api.create_iou(
            IouCreate(
                forAmount= 5,
                parties=IouParties(
                    issuer=Party(
                        entity={
                            "email": ["jean@noumenadigital.com"],
                        },
                        access={
                            "other": ["jean@noumenadigital.com"],
                        }
                    ),
                    payee= Party(
                        entity={
                            "email": ["jean@noumenadigital.com"],
                        },
                        access={
                            "other": ["jean@noumenadigital.com"],
                        }
                    )
                )
            ),
            None,
            None,
        )
    except NotFoundException as e:
        print(e)
        return
