import {
    Configuration,
    DefaultApi,
    Iou,
    Party
} from '../../generated'
import { EventSourcePolyfill, MessageEvent } from 'event-source-polyfill'
import Keycloak from 'keycloak-js'
import { useEffect, useState } from 'react'

export class BaseService {
    private api: DefaultApi
    private apiBaseUrl: string
    private keycloak: Keycloak

    constructor(apiBaseUrl: string, keycloak: Keycloak) {
        this.keycloak = keycloak
        this.apiBaseUrl = apiBaseUrl
        this.api = new DefaultApi(
            new Configuration({
                basePath: apiBaseUrl
            })
        )
    }

    private withAuthorizationHeader = () => {
        return { headers: { Authorization: `Bearer ${this.keycloak.token}` } }
    }

    public useStateStream = (requestRefresh: () => void) => {
        const [active, setActive] = useState(true)
        useEffect(() => {
            const source = new EventSourcePolyfill(
                this.apiBaseUrl + "/api/streams/states",
                this.withAuthorizationHeader()
            )

            source.onmessage = function (_: MessageEvent) {
                requestRefresh()
            }

            source.onopen = function (_: any) {
                setActive(true)
            }

            source.onerror = function (_: any) {
                source.close()
                setActive(false)
            }

            source.addEventListener("state", requestRefresh)

            return () => {
                source.close()
                setActive(false)
            }
        }, [])

        return active
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
