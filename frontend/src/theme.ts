import { createTheme } from '@mui/material/styles'
import { red } from '@mui/material/colors'

// NOUMENA Cloud design theme
const theme = createTheme({
    palette: {
        primary: {
            main: '#6D4C93', // Deep purple from NOUMENA design
            light: '#8B7BA7',
            dark: '#4A3269'
        },
        secondary: {
            main: '#E91E63', // Magenta accent
            light: '#F06292',
            dark: '#AD1457'
        },
        background: {
            default: '#FAFAFB', // Clean light background
            paper: '#FFFFFF'
        },
        text: {
            primary: '#2C3E50',
            secondary: '#7F8C8D'
        },
        divider: '#E8EAED',
        error: {
            main: red.A400
        }
    },
    typography: {
        fontFamily: '"Roboto", "Helvetica", "Arial", sans-serif',
        h4: {
            fontWeight: 600,
            fontSize: '2rem',
            color: '#2C3E50'
        },
        h6: {
            fontWeight: 600,
            fontSize: '1.25rem',
            color: '#2C3E50'
        },
        body1: {
            fontSize: '0.95rem',
            lineHeight: 1.6
        }
    },
    shape: {
        borderRadius: 12
    },
    components: {
        MuiButton: {
            styleOverrides: {
                root: {
                    textTransform: 'none',
                    borderRadius: '8px',
                    padding: '10px 24px',
                    fontWeight: 500,
                    background:
                        'linear-gradient(135deg, #6D4C93 0%, #E91E63 100%)',
                    color: 'white',
                    boxShadow: '0 4px 14px 0 rgba(109, 76, 147, 0.25)',
                    '&:hover': {
                        background:
                            'linear-gradient(135deg, #5D3C83 0%, #D91153 100%)',
                        boxShadow: '0 6px 20px 0 rgba(109, 76, 147, 0.35)'
                    }
                }
            }
        },
        MuiCard: {
            styleOverrides: {
                root: {
                    borderRadius: '16px',
                    boxShadow: '0 2px 12px rgba(0, 0, 0, 0.08)',
                    border: '1px solid #F0F2F5'
                }
            }
        },
        MuiChip: {
            styleOverrides: {
                root: {
                    borderRadius: '6px',
                    fontWeight: 500
                }
            }
        },
        MuiTableHead: {
            styleOverrides: {
                root: {
                    backgroundColor: '#F8F9FA',
                    '& .MuiTableCell-head': {
                        fontWeight: 600,
                        fontSize: '0.875rem',
                        color: '#495057',
                        textTransform: 'uppercase',
                        letterSpacing: '0.5px'
                    }
                }
            }
        }
    }
})

export default theme
