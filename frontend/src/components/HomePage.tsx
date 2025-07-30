import {
    Box,
    Button,
    Card,
    CardContent,
    Chip,
    Container,
    Table,
    TableBody,
    TableCell,
    TableContainer,
    TableHead,
    TableRow,
    Typography
} from '@mui/material'
import { useEffect, useState } from 'react'
import { useServices } from '../ServiceProvider'
import { Iou } from '../api-client/types.gen'
import { CreateIouDialog } from './CreateIouDialog'
import { RepayIouDialog } from './RepayIouDialog'
import { ConfirmIouPaymentDialog } from './ConfirmIouPaymentDialog'
import { getIouList } from '../api-client'

interface ViewDialog {
    open: boolean
    iouId: string
}

export const HomePage = () => {
    const [createIouDialogOpen, setCreateIouDialogOpen] =
        useState<boolean>(false)
    const [repayIouDialogOpen, setRepayIouDialogOpen] = useState<ViewDialog>({
        open: false,
        iouId: ''
    })
    const [confirmIouPaymentDialogOpen, setConfirmIouDialogOpen] =
        useState<ViewDialog>({
            open: false,
            iouId: ''
        })

    const { api, withAuthorizationHeader, useStateStream } = useServices()

    const [iouList, setIouList] = useState<Iou[]>()
    const active = useStateStream(() =>
        getIouList({
            client: api,
            ...withAuthorizationHeader()
        }).then((it) => setIouList(it.data?.items))
    )

    useEffect(() => {
        if (!createIouDialogOpen && !repayIouDialogOpen.open) {
            getIouList({
                client: api,
                ...withAuthorizationHeader()
            }).then((it) => setIouList(it.data?.items))
        }
    }, [
        createIouDialogOpen,
        repayIouDialogOpen.open,
        confirmIouPaymentDialogOpen.open,
        active,
        api,
        withAuthorizationHeader
    ])

    return (
        <Container maxWidth="xl" sx={{ py: 3 }}>
            <Box sx={{ mb: 4 }}>
                <Typography variant="h4" sx={{ mb: 1, fontWeight: 600 }}>
                    Overview
                </Typography>
                <Typography variant="body1" color="text.secondary">
                    Manage your IOUs and track payment status
                </Typography>
            </Box>

            <Box
                display="grid"
                gridTemplateColumns="repeat(auto-fit, minmax(350px, 1fr))"
                gap={3}
                sx={{ mb: 4 }}
            >
                <Card sx={{ p: 3, textAlign: 'center' }}>
                    <Typography
                        variant="h3"
                        sx={{ color: 'primary.main', fontWeight: 700, mb: 1 }}
                    >
                        {iouList?.length || 0}
                    </Typography>
                    <Typography
                        variant="h6"
                        sx={{ color: 'text.secondary', fontWeight: 500 }}
                    >
                        Total IOUs
                    </Typography>
                </Card>

                <Card sx={{ p: 3, textAlign: 'center' }}>
                    <Typography
                        variant="h3"
                        sx={{ color: 'success.main', fontWeight: 700, mb: 1 }}
                    >
                        {iouList?.filter((it) => it['@state'] === 'repaid')
                            .length || 0}
                    </Typography>
                    <Typography
                        variant="h6"
                        sx={{ color: 'text.secondary', fontWeight: 500 }}
                    >
                        Repaid IOUs
                    </Typography>
                </Card>

                <Card sx={{ p: 3, textAlign: 'center' }}>
                    <Typography
                        variant="h3"
                        sx={{ color: 'warning.main', fontWeight: 700, mb: 1 }}
                    >
                        {iouList?.filter((it) => it['@state'] === 'unpaid')
                            .length || 0}
                    </Typography>
                    <Typography
                        variant="h6"
                        sx={{ color: 'text.secondary', fontWeight: 500 }}
                    >
                        Pending IOUs
                    </Typography>
                </Card>
            </Box>

            <Card>
                <CardContent sx={{ p: 0 }}>
                    <Box
                        sx={{
                            p: 3,
                            pb: 2,
                            display: 'flex',
                            justifyContent: 'space-between',
                            alignItems: 'center'
                        }}
                    >
                        <Typography variant="h6" sx={{ fontWeight: 600 }}>
                            IOU Management
                        </Typography>
                        <Button
                            onClick={() => setCreateIouDialogOpen(true)}
                            variant="contained"
                            sx={{
                                background:
                                    'linear-gradient(135deg, #6D4C93 0%, #E91E63 100%)',
                                '&:hover': {
                                    background:
                                        'linear-gradient(135deg, #5D3C83 0%, #D91153 100%)'
                                }
                            }}
                        >
                            Create IOU
                        </Button>
                    </Box>

                    <TableContainer>
                        <Table>
                            <TableHead>
                                <TableRow>
                                    <TableCell>Description</TableCell>
                                    <TableCell align="right">
                                        Total Amount
                                    </TableCell>
                                    <TableCell align="right">
                                        Amount Remaining
                                    </TableCell>
                                    <TableCell align="center">Status</TableCell>
                                    <TableCell align="center">
                                        Actions
                                    </TableCell>
                                </TableRow>
                            </TableHead>
                            <TableBody>
                                {iouList && iouList.length > 0 ? (
                                    iouList.map((it, index) => (
                                        <TableRow
                                            key={index}
                                            hover
                                            sx={{
                                                '&:last-child td, &:last-child th':
                                                    { border: 0 },
                                                cursor: 'pointer'
                                            }}
                                        >
                                            <TableCell>
                                                <Typography
                                                    variant="body2"
                                                    sx={{ fontWeight: 500 }}
                                                >
                                                    {it.description}
                                                </Typography>
                                            </TableCell>
                                            <TableCell align="right">
                                                <Typography
                                                    variant="body2"
                                                    sx={{ fontWeight: 600 }}
                                                >
                                                    ${it.forAmount}
                                                </Typography>
                                            </TableCell>
                                            <TableCell align="right">
                                                <Typography
                                                    variant="body2"
                                                    sx={{
                                                        fontWeight: 600,
                                                        color: 'warning.main'
                                                    }}
                                                >
                                                    ${it.amountOwed}
                                                </Typography>
                                            </TableCell>
                                            <TableCell align="center">
                                                <Chip
                                                    label={it['@state']}
                                                    size="small"
                                                    color={
                                                        it['@state'] ===
                                                        'repaid'
                                                            ? 'success'
                                                            : it['@state'] ===
                                                                'unpaid'
                                                              ? 'warning'
                                                              : 'default'
                                                    }
                                                    sx={{
                                                        textTransform:
                                                            'capitalize',
                                                        fontWeight: 500
                                                    }}
                                                />
                                            </TableCell>
                                            <TableCell align="center">
                                                {it['@state'] === 'unpaid' &&
                                                    it['@actions']?.pay && (
                                                        <Button
                                                            size="small"
                                                            variant="outlined"
                                                            onClick={() =>
                                                                setRepayIouDialogOpen(
                                                                    {
                                                                        open: true,
                                                                        iouId: it[
                                                                            '@id'
                                                                        ]
                                                                    }
                                                                )
                                                            }
                                                            sx={{ mr: 1 }}
                                                        >
                                                            Repay
                                                        </Button>
                                                    )}
                                                {it['@state'] ===
                                                    'payment_confirmation_required' &&
                                                    it['@actions']
                                                        ?.confirmPayment && (
                                                        <Button
                                                            size="small"
                                                            variant="contained"
                                                            onClick={() =>
                                                                setConfirmIouDialogOpen(
                                                                    {
                                                                        open: true,
                                                                        iouId: it[
                                                                            '@id'
                                                                        ]
                                                                    }
                                                                )
                                                            }
                                                        >
                                                            Confirm Payment
                                                        </Button>
                                                    )}
                                            </TableCell>
                                        </TableRow>
                                    ))
                                ) : (
                                    <TableRow>
                                        <TableCell
                                            colSpan={5}
                                            align="center"
                                            sx={{ py: 8 }}
                                        >
                                            <Typography
                                                variant="body1"
                                                color="text.secondary"
                                            >
                                                No IOUs found. Create your first
                                                IOU to get started.
                                            </Typography>
                                        </TableCell>
                                    </TableRow>
                                )}
                            </TableBody>
                        </Table>
                    </TableContainer>
                </CardContent>
            </Card>
            <CreateIouDialog
                open={createIouDialogOpen}
                onClose={() => {
                    setCreateIouDialogOpen(false)
                }}
            />
            <RepayIouDialog
                open={repayIouDialogOpen.open}
                iouId={repayIouDialogOpen.iouId}
                onClose={() => {
                    setRepayIouDialogOpen({
                        open: false,
                        iouId: ''
                    })
                }}
            />
            <ConfirmIouPaymentDialog
                open={confirmIouPaymentDialogOpen.open}
                iouId={confirmIouPaymentDialogOpen.iouId}
                onClose={() => {
                    setConfirmIouDialogOpen({
                        open: false,
                        iouId: ''
                    })
                }}
            />
        </Container>
    )
}
