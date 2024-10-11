import {
    Avatar,
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
    Toolbar
} from '@mui/material'
import MuiAppBar, { AppBarProps as MuiAppBarProps } from '@mui/material/AppBar'
import React, { useEffect, useState } from 'react'
import LanguageIcon from '@mui/icons-material/LanguageOutlined'
import NotificationIcon from '@mui/icons-material/NotificationsOutlined'
import logo from '../logo.svg'
import HomeIcon from '@mui/icons-material/HomeOutlined'
import { Outlet, useLocation, useNavigate } from 'react-router-dom'
import theme from '../theme.ts'
import { useMe } from '../UserProvider.tsx'
import { useKeycloak } from '@react-keycloak/web'
import { SvgIconComponent } from '@mui/icons-material'

const drawerWidth = 240

const Main = styled('main', { shouldForwardProp: (prop) => prop !== 'open' })<{
    open?: boolean
}>(() => ({
    flexGrow: 1,
    marginLeft: `${drawerWidth}px`
}))

interface AppBarProps extends MuiAppBarProps {
    open?: boolean
}

const AppBar = styled(MuiAppBar, {
    shouldForwardProp: (prop) => prop !== 'open'
})<AppBarProps>(({ theme, open }) => ({
    transition: theme.transitions.create(['margin', 'width'], {
        easing: theme.transitions.easing.sharp,
        duration: theme.transitions.duration.leavingScreen
    }),
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
    const { keycloak } = useKeycloak()

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
        await keycloak.logout()
    }

    return (
        <ThemeProvider theme={theme}>
            <CssBaseline />
            <AppBar
                position="fixed"
                sx={{ bgcolor: theme.palette.background.default }}
                elevation={0}
            >
                <Toolbar sx={{ justifyContent: 'flex-end' }}>
                    <LanguageIcon
                        sx={{ color: 'black', marginRight: '18px' }}
                    ></LanguageIcon>
                    <NotificationIcon
                        sx={{ color: 'black', marginRight: '18px' }}
                    ></NotificationIcon>
                    <Box
                        onClick={handlePortraitClick}
                        sx={{
                            display: 'flex',
                            alignItems: 'center',
                            border: 1,
                            borderColor: theme.palette.primary.main,
                            borderRadius: '24px',
                            padding: '8px'
                        }}
                    >
                        <Box color={'black'} paddingRight={1}>
                            Hi, {name}
                        </Box>
                        <Avatar
                            sx={{
                                width: 26,
                                height: 26,
                                bgcolor: theme.palette.primary.main,
                                color: 'black'
                            }}
                        >
                            {name.substring(0, 1)}
                        </Avatar>
                    </Box>
                    <Menu
                        id="basic-menu"
                        anchorOrigin={{
                            vertical: 'bottom',
                            horizontal: 'center'
                        }}
                        anchorEl={anchorEl}
                        open={open}
                        onClose={() => setAnchorEl(null)}
                    >
                        <MenuItem onClick={logout}>Logout</MenuItem>
                    </Menu>
                </Toolbar>
            </AppBar>
            <Drawer
                sx={{
                    width: drawerWidth,
                    flexShrink: 0,
                    '& .MuiDrawer-paper': {
                        width: drawerWidth,
                        boxSizing: 'border-box'
                    }
                }}
                variant="persistent"
                anchor="left"
                open={true}
            >
                <Box sx={{ width: '100%', maxWidth: 360, padding: '20px' }}>
                    <Box
                        sx={{
                            display: 'flex',
                            paddingBottom: '24px',
                            paddingTop: '12px'
                        }}
                    >
                        <img src={logo} alt="" />
                    </Box>
                    <Box sx={{ display: 'flex', fontSize: '12px' }}>MENU</Box>
                    <List component="nav">
                        {menuItems.map((it, index) => (
                            <ListItemButton
                                key={index}
                                selected={it === selected}
                                onClick={() => handleClick(it)}
                            >
                                <ListItemIcon>
                                    <it.icon />
                                </ListItemIcon>
                                <ListItemText primary={it.label} />
                            </ListItemButton>
                        ))}
                    </List>
                </Box>
            </Drawer>
            <Main open={true}>
                <DrawerHeader />
                <Box sx={{ padding: '24px' }}>
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
