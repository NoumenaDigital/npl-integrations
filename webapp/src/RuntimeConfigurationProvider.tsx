import React, { createContext, useContext, useEffect, useState } from 'react'

export interface RuntimeConfiguration {
    apiBaseUrl: string
    keycloakUrl: string
}

const RuntimeConfigurationContext = createContext<RuntimeConfiguration | null>(
    null
)

export const useRuntimeConfiguration = (): RuntimeConfiguration => {
    const configuration = useContext(RuntimeConfigurationContext)
    if (!configuration) {
        throw new Error('Configuration not loaded')
    }
    return configuration
}

interface RuntimeConfigurationProviderProps {
    children: React.ReactNode
}

/**
 * Loads runtime configuration from static file (in /public folder).
 */
export const loadRuntimeConfiguration =
    async (): Promise<RuntimeConfiguration> => {
        const config_file =
            import.meta.env.VITE_ENV == 'DOCKER'
                ? '/config-docker.json'
                : '/config-noumena-cloud.json'
        const response = await fetch(config_file)
        const value = await response.json()

        return {
            apiBaseUrl: value.API_BASE_URL,
            keycloakUrl: value.KEYCLOAK_URL
        }
    }

export const RuntimeConfigurationProvider: React.FC<
    RuntimeConfigurationProviderProps
> = ({ children }) => {
    const [runtimeConfig, setRuntimeConfig] =
        useState<RuntimeConfiguration | null>(null)

    useEffect(() => {
        const loadConfig = async () => {
            console.debug('Loading runtime configuration')
            const loadedConfig = await loadRuntimeConfiguration()
            setRuntimeConfig(loadedConfig)
        }
        loadConfig()
    }, [])

    return (
        <RuntimeConfigurationContext.Provider value={runtimeConfig}>
            {runtimeConfig ? children : <div>&nbsp;</div>}
        </RuntimeConfigurationContext.Provider>
    )
}
