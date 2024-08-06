import {
    Box,
    Button,
    Card,
    CardContent,
    Chip,
    Container,
    Paper,
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
import { Iou } from '../../generated'
import { CreateIouDialog } from './CreateIouDialog'
import { RepayIouDialog } from './RepayIouDialog'
import { ConfirmIouPaymentDialog } from './ConfirmIouPaymentDialog'

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

    const { getIouList, useStateStream } = useServices()

    const [iouList, setIouList] = useState<Iou[]>()
    const active = useStateStream(() =>
        getIouList().then((it) => setIouList(it))
    )

    useEffect(() => {
        if (!createIouDialogOpen && !repayIouDialogOpen.open) {
            getIouList().then((it) => setIouList(it))
        }
    }, [
        createIouDialogOpen,
        repayIouDialogOpen.open,
        confirmIouPaymentDialogOpen.open,
        active
    ])

    return (
        <Container>
            <Typography variant={'h4'}>Home</Typography>
            <br />
            <Box display={'flex'} flexWrap={'wrap'}>
                <Card sx={{ width: '100%' }}>
                    <CardContent>
                        <Box display={'flex'} justifyContent={'space-between'}>
                            <Typography variant={'h6'}>Open IOUs</Typography>
                            <br />
                            <Button
                                onClick={() => setCreateIouDialogOpen(true)}
                            >
                                Create Iou
                            </Button>
                        </Box>
                        <br />
                        <TableContainer component={Paper}>
                            <Table
                                sx={{ minWidth: 650 }}
                                aria-label="simple table"
                            >
                                <TableHead sx={{ bgcolor: '#F4F6F8' }}>
                                    <TableRow>
                                        <TableCell>Name</TableCell>
                                        <TableCell>Total Amount</TableCell>
                                        <TableCell>Amount Remaining</TableCell>
                                        {false && (
                                            <TableCell>
                                                Inbound/Outbound
                                            </TableCell>
                                        )}
                                        <TableCell>State</TableCell>
                                        <TableCell />
                                    </TableRow>
                                </TableHead>
                                <TableBody>
                                    {(iouList &&
                                        iouList.length > 0 &&
                                        iouList.map((it, index) => (
                                            <TableRow
                                                key={index}
                                                hover={true}
                                                sx={{
                                                    cursor: 'pointer',
                                                    '&:last-child td, &:last-child th':
                                                        {
                                                            border: 0
                                                        }
                                                }}
                                            >
                                                <TableCell>
                                                    {it.description}
                                                </TableCell>
                                                <TableCell>
                                                    {it.forAmount}
                                                </TableCell>
                                                <TableCell>
                                                    {it.amountOwed}
                                                </TableCell>
                                                {false && (
                                                    <TableCell>
                                                        to be implemented
                                                    </TableCell>
                                                )}
                                                <TableCell>
                                                    <Chip
                                                        color={'secondary'}
                                                        label={it['@state']}
                                                    ></Chip>
                                                </TableCell>
                                                <TableCell>
                                                    {it['@state'] ==
                                                        'unpaid' && (
                                                        <Button
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
                                                        >
                                                            Repay
                                                        </Button>
                                                    )}
                                                    {it['@state'] ==
                                                        'payment_confirmation_required' && (
                                                        <Button
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
                                        ))) || <div>No Iou entry found</div>}
                                </TableBody>
                            </Table>
                        </TableContainer>
                    </CardContent>
                </Card>
            </Box>
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
