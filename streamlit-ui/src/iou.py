from npl_objects_lib.api.default_api import DefaultApi
from npl_objects_lib.models.iou_create import IouCreate
from npl_objects_lib.models.iou_parties import IouParties
from npl_objects_lib.models.party import Party


def create_iou(api: DefaultApi, description: str, amount: float, issuer: str, payee: str):
    return api.create_iou(
        IouCreate(
            description=description,
            forAmount=amount,
            parties=IouParties(
                issuer=Party(
                    claims={
                        "email": [issuer],
                    }
                ),
                payee=Party(
                    claims={
                        "email": [payee],
                    }
                )
            )
        )
    )
