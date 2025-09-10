import React, { createContext, useContext, useEffect, useState } from 'react'

type LoginMode = 'KEYCLOAK' | 'CUSTOM_OIDC' | 'DEV_MODE'
type DeploymentTarget = 'LOCAL' | 'NOUMENA_CLOUD'

export interface RuntimeConfiguration {
    apiBaseUrl: string
    authUrl: string
    realm: string | undefined
    clientId: string | undefined
    loginMode: LoginMode
    deploymentTarget: DeploymentTarget
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
 * Loads runtime configuration from environment variables.
 */
export const loadRuntimeConfiguration = () => {
    const loginMode =
        (import.meta.env.VITE_LOGIN_MODE as LoginMode) || 'CUSTOM_OIDC'
    const deploymentTarget =
        (import.meta.env.VITE_DEPLOYMENT_TARGET as DeploymentTarget) || 'LOCAL'

    const appSlug = import.meta.env.VITE_NC_APP_NAME
    const tenantSlug = import.meta.env.VITE_NC_ORG_NAME

    let config: RuntimeConfiguration = {
        apiBaseUrl: 'http://localhost:12000',
        authUrl: 'http://localhost:11000',
        realm: '',
        clientId: '',
        loginMode,
        deploymentTarget
    }

    if (deploymentTarget === 'NOUMENA_CLOUD') {
        config.apiBaseUrl =
            import.meta.env.VITE_CLOUD_API_URL ||
            `https://engine-${tenantSlug}-${appSlug}.noumena.cloud`
    } else {
        config.apiBaseUrl =
            import.meta.env.VITE_LOCAL_API_URL || 'http://localhost:12000'
    }

    if (loginMode === 'DEV_MODE') {
        config.authUrl =
            import.meta.env.VITE_LOCAL_AUTH_URL || 'http://localhost:11000'
    } else if (loginMode === 'CUSTOM_OIDC') {
        if (deploymentTarget === 'NOUMENA_CLOUD') {
            config.authUrl =
                (import.meta.env.VITE_CLOUD_AUTH_URL ||
                    'http://localhost:11000') + '/protocol/openid-connect'
        } else {
            config.authUrl =
                (import.meta.env.VITE_LOCAL_AUTH_URL ||
                    'http://localhost:11000') + '/protocol/openid-connect'
        }
        config.realm = appSlug
        config.clientId = appSlug
    } else if (loginMode === 'KEYCLOAK') {
        if (deploymentTarget === 'NOUMENA_CLOUD') {
            config.authUrl =
                import.meta.env.VITE_CLOUD_AUTH_URL ||
                `https://keycloak-${tenantSlug}-${appSlug}.noumena.cloud`
        } else {
            config.authUrl =
                import.meta.env.VITE_LOCAL_AUTH_URL || 'http://localhost:11000'
        }
        config.realm = appSlug
        config.clientId = appSlug
    }

    console.log('Login Mode:', loginMode)
    console.log('Deployment Target:', deploymentTarget)
    console.log('Configuration:', config)

    return config
}

export const RuntimeConfigurationProvider: React.FC<
    RuntimeConfigurationProviderProps
> = ({ children }) => {
    const [runtimeConfig, setRuntimeConfig] =
        useState<RuntimeConfiguration | null>(null)

    useEffect(() => {
        const loadConfig = async () => {
            const loadedConfig = loadRuntimeConfiguration()
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
