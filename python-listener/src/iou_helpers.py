from iou.api.default_api import DefaultApi
from iou.models.iou_create import IouCreate
from iou.models.iou_parties import IouParties
from iou.models.party import Party


def create_iou(api: DefaultApi):
    return api.create_iou(
        IouCreate(
            forAmount=5,
            parties=IouParties(
                issuer=Party(
                    claims={
                        "email": ["jean@noumenadigital.com"],
                    }
                ),
                payee=Party(
                    claims={
                        "email": ["jean@noumenadigital.com"],
                    }
                )
            )
        )
    )
