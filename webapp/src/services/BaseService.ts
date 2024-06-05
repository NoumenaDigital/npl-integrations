import {
    Configuration,
    DefaultApi,
    Iou,
    Party
} from '../../generated'
import Keycloak from 'keycloak-js'

export class BaseService {
    private api: DefaultApi
    private keycloak: Keycloak

    constructor(apiBaseUrl: string, keycloak: Keycloak) {
        this.keycloak = keycloak
        this.api = new DefaultApi(
            new Configuration({
                basePath: apiBaseUrl
            })
        )
    }

    private withAuthorizationHeader = () => {
        return { headers: { Authorization: `Bearer ${this.keycloak.token}` } }
    }

    public getIouList: () => Promise<Iou[]> = async () =>
        this.api
            .getIouList(
                undefined,
                undefined,
                undefined,
                this.withAuthorizationHeader()
            )
            .then((it) => it.data.items)

    public getIou = async (
        iouId: string
    ): Promise<Iou> =>
        await this.api.getIouByID(
            iouId,
            undefined,
            undefined,
            this.withAuthorizationHeader()
        ).then((it) => it.data)

    public pay = async (
        iouId: string,
        amount: number
    ) =>
        await this.api
            .iouPay(
                iouId,
                {
                    amount: amount
                },
                undefined,
                undefined,
                this.withAuthorizationHeader()
            )
            .then((it) => it.data)

    public confirmPayment = async (
            iouId: string,
        ) =>
            await this.api
                .iouConfirmPayment(
                    iouId,
                    undefined,
                    undefined,
                    this.withAuthorizationHeader()
                )
                .then((it) => it.data)

    public createIou = async (
        description: string,
        amount: number,
        issuerEntity: Party['entity'],
        issuerAccess: Party['access'],
        payeeEntity: Party['entity'],
        payeeAccess: Party['access'],
    ) =>
        await this.api
            .createIou(
                {
                    description: description,
                    forAmount: amount,
                    ["@parties"]: {
                        "issuer": {
                            "entity": issuerEntity,
                            "access": issuerAccess
                        },
                        "payee": {
                            "entity": payeeEntity,
                            "access": payeeAccess
                        },
                    }
                },
                undefined,
                undefined,
                this.withAuthorizationHeader()
            )
            .then((it) => it.data)
}
