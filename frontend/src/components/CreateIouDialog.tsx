import React, { useState } from 'react'
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
import { useMe } from '../UserProvider.tsx'
import { useServices } from '../ServiceProvider.tsx'
import { createIou } from '../api-client'

export const CreateIouDialog: React.FC<{
    open: boolean
    onClose: (_: boolean) => void
}> = ({ open, onClose }) => {
    const user = useMe()
    const { api, withAuthorizationHeader } = useServices()
    const [description, setDescription] = useState<string>('')
    const [payee, setPayee] = useState<string>('')
    const [forAmount, setForAmount] = useState<number>()

    const [valid, setValid] = useState(false)

    const create = async () => {
        await createIou({
            body: {
                description: description,
                forAmount: forAmount || 0,
                ['@parties']: {
                    issuer: {
                        entity: {
                            email: [user.email]
                        },
                        access: {}
                    },
                    payee: {
                        entity: {
                            email: [payee]
                        },
                        access: {}
                    }
                }
            },
            method: 'POST',
            client: api,
            ...withAuthorizationHeader()
        }).then(() => onClose(true))
    }

    const handleForAmountChange = (input: string) => {
        try {
            if (input !== '') {
                setForAmount(parseInt(input, 10))
                setValid(true)
            } else {
                setValid(false)
            }
        } catch (e: unknown) {
            setValid(false)
        }
    }

    const handleDescriptionChange = (input: string) => {
        setDescription(input)
    }

    const handlePayeeChange = (input: string) => {
        setPayee(input)
    }

    return (
        <Dialog open={open} onClose={onClose} fullWidth={true} maxWidth={'lg'}>
            <DialogTitle
                variant={'h4'}
                fontWeight={'bold'}
                textAlign={'center'}
            >
                {' '}
                Create new IOU
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
                            label={`Description`}
                            variant="outlined"
                            value={description}
                            type={'string'}
                            onChange={(e) =>
                                handleDescriptionChange(e.target.value)
                            }
                        />
                    </FormControl>
                    <br />
                    <FormControl sx={{ m: 1, width: '50%' }}>
                        <TextField
                            id="outlined-basic"
                            focused={true}
                            label={`For Amount`}
                            variant="outlined"
                            value={forAmount}
                            type={'number'}
                            onChange={(e) =>
                                handleForAmountChange(e.target.value)
                            }
                        />
                    </FormControl>
                    <br />
                    <FormControl sx={{ m: 1, width: '50%' }}>
                        <TextField
                            id="outlined-basic"
                            focused={true}
                            label={`Payee`}
                            variant="outlined"
                            value={payee}
                            type={'email'}
                            onChange={(e) => handlePayeeChange(e.target.value)}
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
                    onClick={create}
                    disabled={!valid}
                >
                    Create
                </Button>
            </DialogActions>
        </Dialog>
    )
}
