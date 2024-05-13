import React from 'react'
import ReactDOM from 'react-dom/client'
import './index.css'
import '@fontsource/roboto/300.css'
import '@fontsource/roboto/400.css'
import '@fontsource/roboto/500.css'
import '@fontsource/roboto/700.css'
import { CssBaseline } from '@mui/material'
import { RouterProvider } from 'react-router-dom'
import { KeycloakProvider } from './KeycloakProvider.tsx'
import { RuntimeConfigurationProvider } from './RuntimeConfigurationProvider.tsx'
import { ServiceProvider } from './ServiceProvider.tsx'
import { UserProvider } from './UserProvider.tsx'
import { router } from './Router.tsx'

export const IouApp = () => {
    return (
        <React.StrictMode>
            <CssBaseline></CssBaseline>
            <RouterProvider router={router()} />
        </React.StrictMode>
    )
}

ReactDOM.createRoot(document.getElementById('root')!).render(
    <RuntimeConfigurationProvider>
        <KeycloakProvider>
            <ServiceProvider>
                <UserProvider>
                    <IouApp></IouApp>
                </UserProvider>
            </ServiceProvider>
        </KeycloakProvider>
    </RuntimeConfigurationProvider>
)
