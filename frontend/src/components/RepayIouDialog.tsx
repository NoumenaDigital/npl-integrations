import React, { useEffect, useState } from 'react'
import {
    Box,
    Button,
    Dialog,
    DialogActions,
    DialogContent,
    DialogTitle,
    Divider,
    FormControl,
    TextField
} from '@mui/material'
import { useServices } from '../ServiceProvider.tsx'
import { Iou } from '../api-client/types.gen'
import { getIouById, iouPay } from '../api-client/sdk.gen.ts'

export const RepayIouDialog: React.FC<{
    iouId: string
    open: boolean
    onClose: (_: boolean) => void
}> = ({ iouId, open, onClose }) => {
    const { api, withAuthorizationHeader } = useServices()

    const [iou, setIou] = useState<Iou>()

    const [amount, setAmount] = useState<number>(0)
    const [valid, setValid] = useState(false)

    useEffect(() => {
        if (iouId && iouId !== '') {
            getIouById({
                client: api,
                path: {
                    id: iouId
                },
                ...withAuthorizationHeader()
            }).then((it) => setIou(it.data))
        }
    }, [api, withAuthorizationHeader, iouId])

    const payAction = async () => {
        await iouPay({
            client: api,
            path: {
                id: iouId
            },
            body: {
                amount: amount
            },
            method: 'POST',
            ...withAuthorizationHeader()
        }).then(() => onClose(true))
    }

    const handleAmountChange = (input: string) => {
        try {
            setAmount(parseInt(input, 10))
            setValid(true)
        } catch (e: unknown) {
            setValid(false)
        }
    }

    return (
        <Dialog open={open} onClose={onClose} fullWidth={true} maxWidth={'lg'}>
            <DialogTitle
                variant={'h4'}
                fontWeight={'bold'}
                textAlign={'center'}
            >
                {' '}
                Repay {iou?.description}
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
                    <FormControl sx={{ m: 1, width: '50%' }}>
                        <TextField
                            id="outlined-basic"
                            focused={true}
                            label={`Amount`}
                            variant="outlined"
                            value={amount}
                            type={'number'}
                            onChange={(e) => handleAmountChange(e.target.value)}
                        />
                    </FormControl>
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
                    onClick={payAction}
                    disabled={!valid}
                >
                    Pay
                </Button>
            </DialogActions>
        </Dialog>
    )
}
