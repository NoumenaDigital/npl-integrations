import React, { createContext, useContext, useEffect, useState } from 'react'

export interface RuntimeConfiguration {
    apiBaseUrl: string
    keycloakUrl: string
    keycloakRealm: string
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
        console.log('VITE_ENV: ', import.meta.env.VITE_ENV)
        console.log('NODE_ENV: ', process.env.NODE_ENV)
        console.log('MODE: ', import.meta.env.MODE)
        const config_file =
            import.meta.env.VITE_ENV == 'DOCKER'
                ? '/config-docker.json'
                : '/config-noumena-cloud.json'
        const response = await fetch(config_file)
        const value = await response.json()

        let keycloakRealm = import.meta.env.VITE_NC_APP_NAME
        let ncOrg = import.meta.env.VITE_NC_ORG_NAME

        console.log('keycloakRealm: ', keycloakRealm)
        console.log('ncOrg: ', ncOrg)
        let config = {
            apiBaseUrl: value.API_BASE_URL,
            keycloakUrl: value.KEYCLOAK_URL,
            keycloakRealm: value.KEYCLOAK_REALM,
        }
        if (keycloakRealm !== undefined) {
            config = {
                ...config,
                apiBaseUrl: config.apiBaseUrl.replace("nplintegrations", keycloakRealm),
                keycloakUrl: config.keycloakUrl.replace("nplintegrations", keycloakRealm),
                keycloakRealm: keycloakRealm,
            }
        }
        if (ncOrg !== undefined) {
            config = {
                ...config,
                apiBaseUrl: config.apiBaseUrl.replace("noumena", ncOrg),
                keycloakUrl: config.keycloakUrl.replace("noumena", ncOrg),
            }
        }
        console.log('Runtime Env: ', import.meta.env)
        return config
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
