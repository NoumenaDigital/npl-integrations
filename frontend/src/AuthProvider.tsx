import React, { FC } from 'react'
import { KeycloakProvider } from './KeycloakProvider.tsx'
import { DirectOidcProvider } from './DirectOidcProvider.tsx'
import { useRuntimeConfiguration } from './RuntimeConfigurationProvider.tsx'

interface AuthProviderProps {
    children: React.ReactNode
}

export const AuthProvider: FC<AuthProviderProps> = ({ children }) => {
    const { loginMode } = useRuntimeConfiguration()

    if (loginMode === 'KEYCLOAK') {
        return <KeycloakProvider>{children}</KeycloakProvider>
    }

    return <DirectOidcProvider>{children}</DirectOidcProvider>
}
