import React, { createContext, useContext, useEffect, useState } from 'react'
import { useRuntimeConfiguration } from './RuntimeConfigurationProvider.tsx'
import { useKeycloak } from '@react-keycloak/web'
import { useDirectOidc } from './DirectOidcProvider.tsx'
import { Box, CircularProgress } from '@mui/material'
import { KeycloakTokenParsed } from 'keycloak-js'

export interface User {
    name: string
    email: string
}

const UserContext = createContext<User | null>(null)

export const useMe = (): User => {
    const configuration = useContext(UserContext)
    if (!configuration) {
        throw new Error('User not initialized')
    }
    return configuration
}

interface UserProviderProps {
    children: React.ReactNode
}

export const UserProvider: React.FC<UserProviderProps> = ({ children }) => {
    const { apiBaseUrl, loginMode } = useRuntimeConfiguration()
    const [user, setUser] = useState<User | null>(null)

    // Keycloak hooks (only used in KEYCLOAK mode)
    let keycloak, initialized
    try {
        const keycloakAuth = useKeycloak()
        keycloak = keycloakAuth.keycloak
        initialized = keycloakAuth.initialized
    } catch {
        // Not in Keycloak context
        keycloak = null
        initialized = false
    }

    // DirectOidc hooks (only used in CUSTOM_OIDC mode)
    let directOidcAuth
    try {
        directOidcAuth = useDirectOidc()
    } catch {
        // Not in DirectOidc context
        directOidcAuth = null
    }

    useEffect(() => {
        if (loginMode === 'KEYCLOAK') {
            if (initialized && keycloak?.tokenParsed) {
                internalizeUser(keycloak.tokenParsed).then((it) => setUser(it))
            }
        } else if (loginMode === 'CUSTOM_OIDC') {
            if (directOidcAuth?.isAuthenticated && directOidcAuth.user) {
                setUser(directOidcAuth.user)
            }
        }
    }, [apiBaseUrl, keycloak, initialized, directOidcAuth, loginMode])

    return (
        <UserContext.Provider value={user}>
            {user ? children : <Loading></Loading>}
        </UserContext.Provider>
    )
}

const Loading = () => {
    return (
        <Box
            display={'flex'}
            justifyContent={'center'}
            alignItems={'center'}
            height={'100vh'}
        >
            <CircularProgress />
        </Box>
    )
}

const internalizeUser = async (
    tokenParsed: KeycloakTokenParsed
): Promise<User> => {
    if (tokenParsed.name && tokenParsed.email) {
        return {
            name: tokenParsed.name as string,
            email: tokenParsed.email as string
        }
    } else {
        throw Error(
            `unable to parse user from ${(tokenParsed.name, tokenParsed.email, tokenParsed.company)}`
        )
    }
}
