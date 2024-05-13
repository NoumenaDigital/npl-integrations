import React, { createContext, useContext, useEffect, useState } from 'react'
import { useRuntimeConfiguration } from './RuntimeConfigurationProvider.tsx'
import { useKeycloak } from '@react-keycloak/web'
import { Box, CircularProgress } from '@mui/material'

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
    const { apiBaseUrl } = useRuntimeConfiguration()
    const { keycloak, initialized } = useKeycloak()
    const [user, setUser] = useState<User | null>(null)

    useEffect(() => {
        if (initialized && keycloak.tokenParsed) {
            internalizeUser(keycloak.tokenParsed).then((it) => setUser(it))
        }
    }, [apiBaseUrl, keycloak, initialized])

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

const internalizeUser = async (tokenParsed: any): Promise<User> => {
    if (tokenParsed.name && tokenParsed.email) {
        return {
            name: tokenParsed.name as string,
            email: tokenParsed.email as string,
        }
    } else {
        throw Error(
            `unable to parse user from ${(tokenParsed.name, tokenParsed.email, tokenParsed.company)}`
        )
    }
}
