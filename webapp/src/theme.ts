import { createTheme } from '@mui/material/styles'
import { red } from '@mui/material/colors'

// A custom theme for this app
const theme = createTheme({
    palette: {
        primary: {
            main: '#19857b'
        },
        secondary: {
            main: '#9ECFCA'
        },
        background: {
            default: '#F3F4F9'
        },
        error: {
            main: red.A400
        }
    }
})

export default theme
