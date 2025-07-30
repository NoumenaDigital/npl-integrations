import {
    Box,
    CssBaseline,
    Drawer,
    List,
    ListItemButton,
    ListItemIcon,
    ListItemText,
    Menu,
    MenuItem,
    styled,
    ThemeProvider,
    Toolbar,
    Typography
} from '@mui/material'
import MuiAppBar, { AppBarProps as MuiAppBarProps } from '@mui/material/AppBar'
import React, { useEffect, useState } from 'react'
import HomeIcon from '@mui/icons-material/HomeOutlined'
import { Outlet, useLocation, useNavigate } from 'react-router-dom'
import theme from '../theme.ts'
import { useMe } from '../UserProvider.tsx'
import { useKeycloak } from '@react-keycloak/web'
import { SvgIconComponent } from '@mui/icons-material'
import { useRuntimeConfiguration } from '../RuntimeConfigurationProvider.tsx'
import { useDirectOidc } from '../DirectOidcProvider.tsx'

const drawerWidth = 240

const Main = styled('main', { shouldForwardProp: (prop) => prop !== 'open' })<{
    open?: boolean
}>(() => ({
    flexGrow: 1,
    marginLeft: `${drawerWidth}px`,
    paddingLeft: '24px'
}))

interface AppBarProps extends MuiAppBarProps {
    open?: boolean
}

const AppBar = styled(MuiAppBar, {
    shouldForwardProp: (prop) => prop !== 'open'
})<AppBarProps>(({ theme, open }) => ({
    ...(open && {
        width: `calc(100% - ${drawerWidth}px)`,
        marginLeft: `${drawerWidth}px`,
        transition: theme.transitions.create(['margin', 'width'], {
            easing: theme.transitions.easing.easeOut,
            duration: theme.transitions.duration.enteringScreen
        })
    })
}))

const DrawerHeader = styled('div')(({ theme }) => ({
    display: 'flex',
    alignItems: 'center',
    padding: theme.spacing(0, 1),
    // necessary for content to be below app bar
    ...theme.mixins.toolbar,
    justifyContent: 'flex-end'
}))

type MenuLabel = 'Home'

interface MenuItem {
    label: MenuLabel
    icon: SvgIconComponent
}

const allMenuItems: MenuItem[] = [{ label: 'Home', icon: HomeIcon }]

export default function Shell() {
    const navigate = useNavigate()
    const { pathname } = useLocation()

    const { name } = useMe()
    const { loginMode } = useRuntimeConfiguration()
    const isKeycloak = loginMode === 'KEYCLOAK'
    const isDirectOidc = loginMode === 'CUSTOM_OIDC'
    const { keycloak } = isKeycloak ? useKeycloak() : { keycloak: null }
    const { logout: oidcLogout } = isDirectOidc
        ? useDirectOidc()
        : { logout: () => {} }

    const menuItems = allMenuItems

    const [selected, setSelected] = useState(menuItems[0])
    const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null)
    const open = Boolean(anchorEl)

    useEffect(() => {
        setSelected(toMenuItem(pathname))
    }, [pathname])

    const handleClick = (menuItem: MenuItem) => {
        setSelected(menuItem)
        navigate(menuItem.label.toLowerCase())
    }

    const handlePortraitClick = (event: React.MouseEvent<HTMLElement>) => {
        setAnchorEl(event.currentTarget)
    }

    const logout = async () => {
        if (isKeycloak) {
            await keycloak!.logout()
        } else if (isDirectOidc) {
            oidcLogout()
        }
    }

    return (
        <ThemeProvider theme={theme}>
            <CssBaseline />
            <AppBar
                position="fixed"
                sx={{
                    bgcolor: theme.palette.background.paper,
                    borderBottom: `1px solid ${theme.palette.divider}`,
                    boxShadow: '0 1px 3px rgba(0, 0, 0, 0.05)'
                }}
                elevation={0}
            >
                <Toolbar sx={{ justifyContent: 'space-between', px: 3 }}>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                    </Box>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                        <Typography
                            variant="body2"
                            sx={{ color: theme.palette.text.secondary }}
                        >
                            Community
                        </Typography>
                        <Typography
                            variant="body2"
                            sx={{ color: theme.palette.text.secondary }}
                        >
                            Documentation
                        </Typography>
                        <Typography
                            variant="body2"
                            sx={{ color: theme.palette.text.secondary }}
                        >
                            Support
                        </Typography>
                        <Box
                            onClick={handlePortraitClick}
                            sx={{
                                display: 'flex',
                                alignItems: 'center',
                                bgcolor: theme.palette.primary.main,
                                borderRadius: '20px',
                                padding: '6px 12px',
                                cursor: 'pointer',
                                transition: 'all 0.2s',
                                '&:hover': {
                                    bgcolor: theme.palette.primary.dark
                                }
                            }}
                        >
                            <Typography
                                variant="body2"
                                sx={{ color: 'white', mr: 1, fontWeight: 500 }}
                            >
                                {name}
                            </Typography>
                        </Box>
                        <Menu
                            id="basic-menu"
                            anchorOrigin={{
                                vertical: 'bottom',
                                horizontal: 'right'
                            }}
                            transformOrigin={{
                                vertical: 'top',
                                horizontal: 'right'
                            }}
                            anchorEl={anchorEl}
                            open={open}
                            onClose={() => setAnchorEl(null)}
                            slotProps={{
                                paper: {
                                    sx: {
                                        borderRadius: '8px',
                                        boxShadow:
                                            '0 4px 20px rgba(0, 0, 0, 0.1)',
                                        border: `1px solid ${theme.palette.divider}`
                                    }
                                }
                            }}
                        >
                            <MenuItem
                                onClick={logout}
                                sx={{ fontSize: '0.875rem' }}
                            >
                                Logout
                            </MenuItem>
                        </Menu>
                    </Box>
                </Toolbar>
            </AppBar>
            <Drawer
                sx={{
                    width: drawerWidth,
                    flexShrink: 0,
                    '& .MuiDrawer-paper': {
                        width: drawerWidth,
                        boxSizing: 'border-box',
                        bgcolor: theme.palette.background.paper,
                        borderRight: `1px solid ${theme.palette.divider}`,
                        boxShadow: '2px 0 8px rgba(0, 0, 0, 0.05)'
                    }
                }}
                variant="persistent"
                anchor="left"
                open={true}
            >
                <Box sx={{ p: 3, pt: 4 }}>
                    <Box sx={{ mb: 4, mt: 2 }}>
                        <Typography
                            variant="h5"
                            sx={{
                                fontWeight: 700,
                                background:
                                    'linear-gradient(135deg, #6D4C93 0%, #E91E63 100%)',
                                backgroundClip: 'text',
                                WebkitBackgroundClip: 'text',
                                WebkitTextFillColor: 'transparent',
                                letterSpacing: '0.5px'
                            }}
                        >
                            NOVEL
                        </Typography>
                    </Box>


                    <List component="nav" sx={{ p: 0 }}>
                        {menuItems.map((it, index) => (
                            <ListItemButton
                                key={index}
                                selected={it === selected}
                                onClick={() => handleClick(it)}
                                sx={{
                                    borderRadius: '8px',
                                    mb: 0.5,
                                    '&.Mui-selected': {
                                        bgcolor: theme.palette.primary.main,
                                        color: 'white',
                                        '&:hover': {
                                            bgcolor: theme.palette.primary.dark
                                        },
                                        '& .MuiListItemIcon-root': {
                                            color: 'white'
                                        }
                                    },
                                    '&:hover': {
                                        bgcolor: `${theme.palette.primary.main}10`
                                    }
                                }}
                            >
                                <ListItemIcon sx={{ minWidth: '40px' }}>
                                    <it.icon />
                                </ListItemIcon>
                                <ListItemText
                                    primary={it.label}
                                    slotProps={{
                                        primary: {
                                            sx: {
                                                fontWeight: 500,
                                                fontSize: '0.9rem'
                                            }
                                        }
                                    }}
                                />
                            </ListItemButton>
                        ))}
                    </List>
                </Box>
            </Drawer>
            <Main open={true}>
                <DrawerHeader />
                <Box sx={{ padding: '24px', paddingLeft: '0px' }}>
                    <Outlet></Outlet>
                </Box>
            </Main>
        </ThemeProvider>
    )
}

const toMenuItem = (path: string): MenuItem => {
    const firstPath = path.split('/')[1]
    const item = allMenuItems.find(
        (it) => it.label.toLowerCase() === firstPath.toLowerCase()
    )

    return item ?? allMenuItems[0]
}
