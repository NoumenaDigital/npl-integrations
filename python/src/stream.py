from dataclasses import dataclass
import json
from time import sleep

from requests_sse import EventSource, MessageEvent

from src import config

from openapi_client.api.default_api import DefaultApi


# @dataclass
# class RepaymentOccurence(): 

class StreamReader:

    def __init__(self, defaultApi: DefaultApi) -> None:
        self.api = defaultApi
        pass

    def readStream(self, access_token: str):
        with EventSource(config.ROOT_URL + "/api/streams/notifications", timeout=30, headers= {'Authorization': 'Bearer ' + access_token}) as event_source:
            try:
                for event in event_source:
                    if(isinstance(event, MessageEvent) and event.type == "tick"):
                        continue

                    yield json.loads(event.data)
            except KeyboardInterrupt:
                exit

    def manageNotification(self, event: MessageEvent):
        if event.type == "notify":
            print(notificationData)
            notificationData = event["notification"]
            print("Received", notificationData["name"].split('/')[-1])
            iouId = notificationData["refId"]
            paymentAmount = notificationData["arguments"][0]["value"]
            remainderAmount = notificationData["arguments"][1]["value"]
            
            sleep(5) # Sleeping for allowing time to see the state before confirming the payment

            if remainderAmount == 0:
                self.api.iou_confirm_repayment(iouId)
            else:
                self.api.iou_acknowledge_payment(iouId)

            print("Payment acknowledged: ", paymentAmount)
        
        else: 
            print(event)
        
