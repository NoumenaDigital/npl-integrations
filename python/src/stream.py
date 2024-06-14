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

class StreamReader:

    def __init__(self, defaultApi: DefaultApi) -> None:
        self.api = defaultApi
        pass

    def readStream(self, access_token: str):
        with EventSource(config.ROOT_URL + "/api/streams/notifications", timeout=30, headers= {'Authorization': 'Bearer ' + access_token}) as event_source:
            try:
                for event in event_source:
                    if not isinstance(event, MessageEvent):
                        print("unrecognise event", event)
                    elif event.type == "tick":
                        continue
                    elif event.type in ["notify"]:
                        yield json.loads(event.data)["notification"]
                    else:
                        print("unrecognise message event", event)
            except KeyboardInterrupt:
                exit

    def manageNotification(self, event: dict):
        notification = Notification(**event)
        if '/nplintegrations-1.0?/iou/RepaymentOccurrence' == notification.name:
            print(event.name, event)
            self.manageRepaymentOccurrence(notification)
            print("Acted on notification RepaymentOccurrence")
        else:
            print(event.name, event)
            print("No action in this notification")

    def manageRepaymentOccurrence(self, notification: Notification):
        iouId = notification.refId
        paymentAmount = notification.arguments[0].value
        remainderAmount = notification.arguments[1].value
        
        print(f"""Received{' full' if remainderAmount == 0 else ''}""", notification.name.split('/')[-1])
        
        sleep(5) # Sleeping for allowing time to see the state before confirming the payment

        self.api.iou_confirm_payment(iouId)
        
        print("Payment confirmed:", paymentAmount)
