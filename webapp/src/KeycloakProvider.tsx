import Keycloak from 'keycloak-js'
import React, { FC } from 'react'
import { ReactKeycloakProvider } from '@react-keycloak/web'
import { useRuntimeConfiguration } from './RuntimeConfigurationProvider.tsx'

interface KeycloakProviderProps {
    children: React.ReactNode
}

export const KeycloakProvider: FC<KeycloakProviderProps> = ({ children }) => {
    const { keycloakUrl, keycloakRealm } = useRuntimeConfiguration()

    const keycloak = new Keycloak({
        url: keycloakUrl,
        realm: keycloakRealm,
        clientId: keycloakRealm,
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
