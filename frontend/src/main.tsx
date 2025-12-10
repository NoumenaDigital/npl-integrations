import React from 'react'
import ReactDOM from 'react-dom/client'
import './index.css'
import { CssBaseline } from '@mui/material'
import { RouterProvider } from 'react-router-dom'
import { AuthProvider } from './AuthProvider.tsx'
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
        <AuthProvider>
            <ServiceProvider>
                <UserProvider>
                    <IouApp></IouApp>
                </UserProvider>
            </ServiceProvider>
        </AuthProvider>
    </RuntimeConfigurationProvider>
)
