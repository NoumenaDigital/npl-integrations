import React, { createContext, useContext, useState, useEffect } from 'react'
import {
    Box,
    CircularProgress,
    TextField,
    Button,
    Paper,
    Typography,
    Alert
} from '@mui/material'
import { useRuntimeConfiguration } from './RuntimeConfigurationProvider.tsx'
import { jwtDecode } from 'jwt-decode'
import { CustomOidc } from './CustomOidc.tsx'

interface DirectOidcContextType {
    isAuthenticated: boolean
    user: CustomOidc | null
    login: (credentials: {
        username: string
        password: string
    }) => Promise<void>
    logout: () => void
}

const DirectOidcContext = createContext<DirectOidcContextType | null>(null)

export const useDirectOidc = (): DirectOidcContextType => {
    const context = useContext(DirectOidcContext)
    if (!context) {
        throw new Error('useDirectOidc must be used within DirectOidcProvider')
    }
    return context
}

interface DirectOidcProviderProps {
    children: React.ReactNode
}

export const DirectOidcProvider: React.FC<DirectOidcProviderProps> = ({
    children
}) => {
    const { authUrl, clientId } = useRuntimeConfiguration()
    const [isAuthenticated, setIsAuthenticated] = useState(false)
    const [user, setUser] = useState<CustomOidc | null>(null)
    const [isLoading, setIsLoading] = useState(true)

    useEffect(() => {
        const storedToken = localStorage.getItem('oidc-access-token')
        const storedUser = localStorage.getItem('oidc-user')

        if (storedToken && storedUser) {
            try {
                const userData = JSON.parse(storedUser)
                setUser(userData)
                setIsAuthenticated(true)
            } catch (error) {
                localStorage.removeItem('oidc-access-token')
                localStorage.removeItem('oidc-user')
            }
        }
        setIsLoading(false)
    }, [])

    const login = async (credentials: {
        username: string
        password: string
    }) => {
        try {
            let payload

            if (clientId) {
                payload = {
                    grant_type: 'password',
                    username: credentials.username,
                    password: credentials.password,
                    scope: 'openid profile email',
                    client_id: clientId
                }
            } else {
                payload = {
                    grant_type: 'password',
                    username: credentials.username,
                    password: credentials.password,
                    scope: 'openid profile email'
                }
            }

            const response = await fetch(`${authUrl}/token`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded'
                },
                body: new URLSearchParams(payload)
            })

            if (!response.ok) {
                throw new Error('Login failed')
            }

            const tokenData = await response.json()

            const tokenDataDecoded = jwtDecode(tokenData.access_token) as any

            console.log(tokenDataDecoded)

            const userData: CustomOidc = {
                token: tokenData.access_token,
                name: tokenDataDecoded.name,
                email: tokenDataDecoded.email
            }

            localStorage.setItem('oidc-access-token', tokenData.access_token)
            localStorage.setItem('oidc-user', JSON.stringify(userData))

            setUser(userData)
            setIsAuthenticated(true)
        } catch (error) {
            throw new Error(
                'Authentication failed. Please check your credentials.'
            )
        }
    }

    const logout = () => {
        setUser(null)
        setIsAuthenticated(false)
        localStorage.removeItem('oidc-access-token')
        localStorage.removeItem('oidc-user')
    }

    const authValue: DirectOidcContextType = {
        isAuthenticated,
        user,
        login,
        logout
    }

    if (isLoading) {
        return <Loading />
    }

    return (
        <DirectOidcContext.Provider value={authValue}>
            {isAuthenticated ? children : <LoginForm />}
        </DirectOidcContext.Provider>
    )
}

const LoginForm: React.FC = () => {
    const [username, setUsername] = useState('')
    const [password, setPassword] = useState('')
    const [isLoggingIn, setIsLoggingIn] = useState(false)
    const [error, setError] = useState<string | null>(null)
    const { login } = useDirectOidc()

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault()
        if (!username.trim() || !password.trim()) return

        setIsLoggingIn(true)
        setError(null)

        try {
            await login({ username, password })
        } catch (err) {
            setError(err instanceof Error ? err.message : 'Login failed')
        } finally {
            setIsLoggingIn(false)
        }
    }

    return (
        <Box
            display="flex"
            justifyContent="center"
            alignItems="center"
            height="100vh"
            bgcolor="background.default"
        >
            <Paper elevation={3} sx={{ p: 4, minWidth: 300, maxWidth: 400 }}>
                <Typography
                    variant="h5"
                    component="h1"
                    gutterBottom
                    align="center"
                >
                    OIDC Login
                </Typography>
                {error && (
                    <Alert severity="error" sx={{ mb: 2 }}>
                        {error}
                    </Alert>
                )}
                <form onSubmit={handleSubmit}>
                    <TextField
                        fullWidth
                        label="Username"
                        variant="outlined"
                        margin="normal"
                        value={username}
                        onChange={(e) => setUsername(e.target.value)}
                        required
                        disabled={isLoggingIn}
                    />
                    <TextField
                        fullWidth
                        label="Password"
                        type="password"
                        variant="outlined"
                        margin="normal"
                        value={password}
                        onChange={(e) => setPassword(e.target.value)}
                        required
                        disabled={isLoggingIn}
                    />
                    <Button
                        type="submit"
                        fullWidth
                        variant="contained"
                        sx={{ mt: 3, mb: 2 }}
                        disabled={
                            isLoggingIn || !username.trim() || !password.trim()
                        }
                    >
                        {isLoggingIn ? 'Logging in...' : 'Login'}
                    </Button>
                </form>
            </Paper>
        </Box>
    )
}

const Loading = () => {
    return (
        <Box
            display="flex"
            justifyContent="center"
            alignItems="center"
            height="100vh"
        >
            <CircularProgress />
        </Box>
    )
}
