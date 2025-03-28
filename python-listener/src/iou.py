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
                    entity={
                        "email": ["jean@noumenadigital.com"],
                    },
                    access={
                        "other": ["jean@noumenadigital.com"],
                    }
                ),
                payee=Party(
                    entity={
                        "email": ["jean@noumenadigital.com"],
                    },
                    access={
                        "other": ["jean@noumenadigital.com"],
                    }
                )
            )
        )
    )
