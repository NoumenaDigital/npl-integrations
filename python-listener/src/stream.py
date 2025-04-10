import json

from dataclasses import dataclass, field
from time import sleep
from requests_sse import EventSource, MessageEvent

from iou.api.default_api import DefaultApi
from iou.models.iou_states import IouStates

from src import config

NPL_PREFIX = '/nplintegrations-1.0?'
IOU_PROTOTYPE_ID = NPL_PREFIX + '/iou/Iou'
REPAYMENT_OCCURRENCE_NAME = NPL_PREFIX + '/iou/RepaymentOccurrence'
MULTINODE_REPAYMENT_OCCURRENCE_NAME = NPL_PREFIX + '/iou/RepaymentOccurrenceMultiNode'


@dataclass
class Agent:
    id: str
    party: str


@dataclass
class Argument:
    nplType: str
    value: int


@dataclass
class StructArgument:
    nplType: str
    value: int
    prototypeId: str


@dataclass
class Notification:
    type: str
    refId: str
    protocolVersion: str
    agents: list[Agent]
    created: str
    name: str
    arguments: list[Argument | StructArgument] = field(init=Argument)
    callback: str

    def __post_init__(self):
        self.arguments = [StructArgument(**a_i) if "prototypeId" in a_i else Argument(**a_i) for a_i in self.arguments]
        self.agents = [Agent(**a_i) for a_i in self.agents]


@dataclass
class Payload:
    protocolStateType: str
    created: str
    currentState: str
    fields: any
    id: str
    parties: any
    observers: any
    prototypeId: str
    version: int


class StreamReader:

    def __init__(self, default_api: DefaultApi) -> None:
        self.api = default_api

    def get_stream(self, access_token: str):
        return EventSource(
                config.ROOT_URL + "/api/streams",
                timeout=30,
                headers={'Authorization': 'Bearer ' + access_token}
        )

    def read_stream(self, access_token: str):
        with self.get_stream(access_token) as event_source:
            try:
                for event in event_source:
                    if not isinstance(event, MessageEvent):
                        print("unrecognized event", event)
                    elif event.type == "tick":
                        continue
                    elif event.type in ["notify", "state"]:
                        yield json.loads(event.data)
                    elif event.type in ["command"]:
                        continue  # no action on command according to the business use-case
                    else:
                        print("unrecognized message event", event)
            except KeyboardInterrupt:
                exit()

    def manage_notification(self, event: dict):
        notification = Notification(**event)  # type: ignore
        if notification.name == REPAYMENT_OCCURRENCE_NAME:
            self.manage_repayment_occurrence(notification)
            print("Acted on notification RepaymentOccurrence")
        elif notification.name == MULTINODE_REPAYMENT_OCCURRENCE_NAME:
            print("Received notification RepaymentOccurrenceMultiNode")
        else:
            print("unrecognized notification event", event)
            print("No action in this notification")

    def manage_repayment_occurrence(self, notification: Notification):
        iou_id = notification.refId
        payment_amount = notification.arguments[0].value
        remainder_amount = notification.arguments[1].value

        print(f"""Received{' full' if remainder_amount == 0 else ''}""", notification.name.split('/')[-1])

        sleep(5)  # Sleeping for allowing time to see the state before confirming the payment

        self.api.iou_confirm_payment(iou_id)

        print("Payment confirmed:", payment_amount)

    def manage_state_change(self, event: dict):
        payload = Payload(**event)  # type: ignore
        if payload.prototypeId == IOU_PROTOTYPE_ID \
                and payload.currentState == IouStates.PAYMENT_CONFIRMATION_REQUIRED:
            self.manage_payment_confirmation_required_state_change(payload)
        elif payload.prototypeId == IOU_PROTOTYPE_ID \
                and payload.currentState == IouStates.UNPAID:
            # No action according to the business use-case
            pass
        else:
            print("unrecognized state event", event)

    def manage_payment_confirmation_required_state_change(self, payload: Payload):
        pass
