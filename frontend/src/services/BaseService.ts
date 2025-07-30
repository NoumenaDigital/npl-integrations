import { client } from '../api-client/client.gen'
import { Client } from '../api-client/client/types'
import { EventSourcePolyfill } from 'event-source-polyfill'
import Keycloak from 'keycloak-js'
import { useEffect, useState } from 'react'
import { CustomOidc } from '../CustomOidc'

export class BaseService {
    api: Client
    private apiBaseUrl: string
    private authProvider: Keycloak | CustomOidc

    constructor(apiBaseUrl: string, authProvider: Keycloak | CustomOidc) {
        this.authProvider = authProvider
        this.apiBaseUrl = apiBaseUrl
        this.api = client
        this.api.setConfig({
            baseUrl: apiBaseUrl
        })
    }

    withAuthorizationHeader = () => {
        return {
            headers: { Authorization: `Bearer ${this.authProvider.token}` }
        }
    }

    public useStateStream = (requestRefresh: () => void) => {
        const [active, setActive] = useState(true)

        useEffect(() => {
            const source = new EventSourcePolyfill(
                this.apiBaseUrl + '/api/streams/states',
                this.withAuthorizationHeader()
            )

            // available param: event-source-polyfill.MessageEvent
            source.onmessage = () => requestRefresh()

            source.onopen = () => setActive(true)

            source.onerror = () => {
                source.close()
                setActive(false)
            }

            source.addEventListener('state', requestRefresh)

            return () => {
                source.removeEventListener('state', requestRefresh)
                source.close()
                setActive(false)
            }
        }, [])

        return active
    }
}
