import { createBrowserRouter, Navigate } from 'react-router-dom'
import Shell from './components/Shell.tsx'
import { HomePage } from './components/HomePage.tsx'

export const router = () => {
    return createBrowserRouter([
        {
            element: <Shell></Shell>,
            children: [
                {
                    path: '/home',
                    element: <HomePage />
                },
                {
                    path: '*',
                    element: <Navigate to="/home" />
                }
            ]
        }
    ])
}
