import Keycloak from 'keycloak-js'
import React, { FC } from 'react'
import { ReactKeycloakProvider } from '@react-keycloak/web'
import { useRuntimeConfiguration } from './RuntimeConfigurationProvider.tsx'

interface KeycloakProviderProps {
    children: React.ReactNode
}

export const KeycloakProvider: FC<KeycloakProviderProps> = ({ children }) => {
    const { authUrl, realm, clientId } = useRuntimeConfiguration()

    const keycloak = new Keycloak({
        url: authUrl,
        realm: realm || '',
        clientId: clientId || ''
    })

    const initOptions = {
        onLoad: 'login-required'
    }

    return (
        <ReactKeycloakProvider authClient={keycloak} initOptions={initOptions}>
            {children}
        </ReactKeycloakProvider>
    )
}
