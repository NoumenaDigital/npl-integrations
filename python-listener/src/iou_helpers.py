from npl_objects_lib.api.default_api import DefaultApi
from npl_objects_lib.models.iou_create import IouCreate
from npl_objects_lib.models.iou_parties import IouParties
from npl_objects_lib.models.party import Party


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
