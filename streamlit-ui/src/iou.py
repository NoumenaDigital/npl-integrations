from iou.api.default_api import DefaultApi
from iou.models.iou_create import IouCreate
from iou.models.iou_parties import IouParties
from iou.models.party import Party


def create_iou(api: DefaultApi, description: str, amount: float, issuer: str, payee: str):
    return api.create_iou(
        IouCreate(
            description=description,
            forAmount=amount,
            parties=IouParties(
                issuer=Party(
                    entity={
                        "email": [issuer],
                    },
                    access={}
                ),
                payee=Party(
                    entity={
                        "email": [payee],
                    },
                    access={}
                )
            )
        )
    )
