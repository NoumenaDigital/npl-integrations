import React, { createContext, useContext, useEffect, useState } from 'react'
import { useRuntimeConfiguration } from './RuntimeConfigurationProvider.tsx'
import { useKeycloak } from '@react-keycloak/web'
import { Box, CircularProgress } from '@mui/material'
import { BaseService } from './services/BaseService.ts'

const ServiceContext = createContext<BaseService | null>(null)

export const useServices = (): BaseService => {
    const configuration = useContext(ServiceContext)
    if (!configuration) {
        throw new Error('Service not initialized')
    }
    return configuration
}

interface ServiceProviderProps {
    children: React.ReactNode
}

export const ServiceProvider: React.FC<ServiceProviderProps> = ({
    children
}) => {
    const { apiBaseUrl } = useRuntimeConfiguration()
    const { keycloak, initialized } = useKeycloak()
    const [services, setServices] = useState<BaseService | null>(null)

    useEffect(() => {
        if (initialized && keycloak.token) {
            setServices(new BaseService(apiBaseUrl, keycloak))
        }
    }, [apiBaseUrl, keycloak, initialized])

    return (
        <ServiceContext.Provider value={services}>
            {services ? children : <Loading></Loading>}
        </ServiceContext.Provider>
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
