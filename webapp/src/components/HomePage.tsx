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

interface ViewDialog {
    open: boolean
    iouId: string
}

export const HomePage = () => {

    const [createIouDialogOpen, setCreateIouDialogOpen] = useState<boolean>(false)
    const [viewIouDialogOpen, setViewIouDialogOpen] = useState<ViewDialog>({
        open: false,
        iouId: ""
    })

    const { getIouList } = useServices()

    const [iouList, setIouList] = useState<Iou[]>()
    
    useEffect(() => {
        if (!createIouDialogOpen && !viewIouDialogOpen.open) {
            getIouList().then((it) => setIouList(it))
        }
    }, [createIouDialogOpen, viewIouDialogOpen.open])

    return (
        (
            <Container>
                <Typography variant={'h4'}>Home</Typography>
                <br />
                <Box display={'flex'} flexWrap={'wrap'}>
                    <Card sx={{ width: '100%' }}>
                        <CardContent>
                            <Box display={'flex'} justifyContent={'space-between'}>
                                <Typography variant={'h6'}>
                                    Open IOUs
                                </Typography>
                                <br />
                                <Button
                                    onClick={() => setCreateIouDialogOpen(true)}
                                >
                                    Create Iou
                                </Button>
                            </Box>
                            <br />
                            <TableContainer component={Paper}>
                                <Table sx={{ minWidth: 650 }} aria-label="simple table">
                                    <TableHead sx={{ bgcolor: '#F4F6F8' }}>
                                        <TableRow>
                                            <TableCell>Name</TableCell>
                                            <TableCell>Total Amount</TableCell>
                                            <TableCell>Amount Remaining</TableCell>
                                            {false && <TableCell>Inbound/Outbound</TableCell>}
                                            <TableCell>State</TableCell>
                                            <TableCell />
                                        </TableRow>
                                    </TableHead>
                                    <TableBody>
                                        {iouList && iouList.length > 0 && iouList.map((it, index) => (
                                            <TableRow
                                                key={index}
                                                hover={true}
                                                sx={{
                                                    cursor: 'pointer',
                                                    '&:last-child td, &:last-child th': {
                                                        border: 0
                                                    }
                                                }}
                                            >
                                                <TableCell>{it.description}</TableCell>
                                                <TableCell>{it.forAmount}</TableCell>
                                                <TableCell>{it.amountOwned}</TableCell>
                                                {false && <TableCell>to be implemented</TableCell>}
                                                <TableCell>
                                                    <Chip
                                                        color={'secondary'}
                                                        label={it['@state']}
                                                    ></Chip>
                                                </TableCell>
                                                <TableCell>
                                                    <Button
                                                        onClick={() => setViewIouDialogOpen({
                                                            open: true,
                                                            iouId: it['@id']
                                                        })}
                                                    >
                                                        Repay
                                                    </Button>
                                                </TableCell>
                                            </TableRow>
                                        )) || <div>No Iou entry found</div>}
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
                    open={viewIouDialogOpen.open}
                    iouId={viewIouDialogOpen.iouId}
                    onClose={() => {
                        setViewIouDialogOpen({
                            open: false,
                            iouId: ""
                        })
                    }}
                />
            </Container>
        )
    )
}
