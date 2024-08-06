import React, { useEffect, useState } from 'react'
import {
    Box,
    Button,
    Dialog,
    DialogActions,
    DialogContent,
    DialogTitle,
    Divider,
    TextField
} from '@mui/material'
import { useServices } from '../ServiceProvider.tsx'
import { Iou } from '../../generated/api.ts'

export const ConfirmIouPaymentDialog: React.FC<{
    iouId: string
    open: boolean
    onClose: (subscribed: boolean) => void
}> = ({ iouId, open, onClose }) => {
    const { getIou, confirmPayment } = useServices()

    const [iou, setIou] = useState<Iou>()
    const valid = true

    useEffect(() => {
        if (iouId && iouId !== '') {
            getIou(iouId).then((it) => setIou(it))
        }
    }, [getIou, iouId])

    const confirmAction = async () => {
        await confirmPayment(iouId).then(() => onClose(true))
    }

    return (
        <Dialog open={open} onClose={onClose} fullWidth={true} maxWidth={'lg'}>
            <DialogTitle
                variant={'h4'}
                fontWeight={'bold'}
                textAlign={'center'}
            >
                {' '}
                Confirm payment to {iou?.description}
            </DialogTitle>
            <DialogContent>
                <Divider></Divider>
                <br />
                <Box
                    display={'flex'}
                    flexDirection={'column'}
                    alignItems={'center'}
                >
                    <br />
                    <TextField
                        id="outlined-basic"
                        focused={true}
                        label={`Repayment amount`}
                        variant="outlined"
                        value={iou?.paymentToBeConfirmed?.amount}
                        type={'number'}
                        inputProps={{ readOnly: true }}
                    />
                </Box>
            </DialogContent>
            <DialogActions>
                <Button
                    variant={'contained'}
                    color={'error'}
                    onClick={() => onClose(false)}
                >
                    Cancel
                </Button>
                <Button
                    variant={'contained'}
                    onClick={confirmAction}
                    disabled={!valid}
                >
                    Confirm payment
                </Button>
            </DialogActions>
        </Dialog>
    )
}
