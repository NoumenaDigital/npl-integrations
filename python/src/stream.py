from dataclasses import dataclass, field
import json
from time import sleep
from requests_sse import EventSource, MessageEvent

from openapi_client.api.default_api import DefaultApi

from src import config


@dataclass
class Agent:
    id: str
    party: str


@dataclass
class Argument:
    nplType: str
    value: int


@dataclass
class Notification:
    type: str
    refId: str
    protocolVersion: str
    agents: list[Agent]
    created: str
    name: str
    arguments: list[Argument] = field(init=Argument)
    callback: str

    def __post_init__(self):
        self.arguments = [Argument(**a_i) for a_i in self.arguments]
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

    def __init__(self, defaultApi: DefaultApi, urlExtension: str = "") -> None:
        self.api = defaultApi
        self.urlExtension = urlExtension

    def read_stream(self, access_token: str):
        with EventSource(
                config.ROOT_URL + "/api/streams" + self.urlExtension,
                timeout=30,
                headers={'Authorization': 'Bearer ' + access_token}
        ) as event_source:
            try:
                for event in event_source:
                    if not isinstance(event, MessageEvent):
                        print("unrecognized event", event)
                    elif event.type == "tick":
                        continue
                    elif event.type in ["notify", "state"]:
                        yield json.loads(event.data)
                    elif event.type in ["command"]:
                        continue  # no action on command
                    else:
                        print("unrecognized message event", event)
            except KeyboardInterrupt:
                exit()

    def manage_notification(self, event: dict):
        notification = Notification(**event)  # type: ignore
        if '/nplintegrations-1.0?/iou/RepaymentOccurrence' == notification.name:
            self.manage_repayment_occurrence(notification)
        else:
            print("unrecognized notification event", event)

    def manage_repayment_occurrence(self, notification: Notification):
        iou_id = notification.refId
        payment_amount = notification.arguments[0].value
        remainder_amount = notification.arguments[1].value

        print(f"""Received{' full' if remainder_amount == 0 else ''}""", notification.name.split('/')[-1])

        sleep(5)  # Sleeping for allowing time to see the state before confirming the payment

        self.api.iou_confirm_payment(iou_id)

        print("Payment acknowledged:", payment_amount)

    def manage_state_change(self, event: dict):
        payload = Payload(**event)  # type: ignore
        if '/nplintegrations-1.0?/iou/Iou' == payload.prototypeId \
                and "payment_confirmation_required" == payload.currentState:
            self.manage_payment_confirmation_required_state_change(payload)
        elif '/nplintegrations-1.0?/iou/Iou' == payload.prototypeId \
                and "unpaid" == payload.currentState:
            pass
        else:
            print("unrecognized state event", event)

    def manage_payment_confirmation_required_state_change(self, payload: Payload):
        # todo
        print("TODO complete implementation")
        pass
