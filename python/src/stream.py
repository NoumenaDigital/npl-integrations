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

    def readStream(self, access_token: str):
        with EventSource(
            config.ROOT_URL + "/api/streams" + self.urlExtension,
            timeout=30,
            headers= {'Authorization': 'Bearer ' + access_token}
        ) as event_source:
            try:
                for event in event_source:
                    if not isinstance(event, MessageEvent):
                        print("unrecognise event", event)
                    elif event.type == "tick":
                        continue
                    elif event.type in ["notify", "state"]:
                        yield json.loads(event.data)
                    elif event.type in ["command"]:
                        continue # no action on command
                    else:
                        print("unrecognise message event", event)
            except KeyboardInterrupt:
                exit

    def manageNotification(self, event: dict):
        notification = Notification(**event)
        if '/library-1.0?/objects/iou/RepaymentOccurence' == notification.name:
            self.manageRepaymentOccurrence(notification)
        else:
            print("unrecognise notification event", event)

    def manageRepaymentOccurrence(self, notification: Notification):
        iouId = notification.refId
        paymentAmount = notification.arguments[0].value
        remainderAmount = notification.arguments[1].value
        
        print(f"""Received{' full' if remainderAmount == 0 else ''}""", notification.name.split('/')[-1])
        
        sleep(5) # Sleeping for allowing time to see the state before confirming the payment

        self.api.iou_confirm_payment(iouId)
        
        print("Payment acknowledged:", paymentAmount)

    def manageStateChange(self, event: dict):
        payload = Payload(**event)
        if '/library-1.0?/objects/iou/Iou' == payload.prototypeId \
            and "unpaid_pending_acknowledgement" == payload.currentState:
            self.managePendingAcknowledgementStateChange(payload)
        elif '/library-1.0?/objects/iou/Iou' == payload.prototypeId \
            and "unpaid" == payload.currentState:
            pass
        else:
            print("unrecognise state event", event)

    def managePendingAcknowledgementStateChange(self, payload: Payload):
        # todo
        print("TODO complete implementation")
        pass