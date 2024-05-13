import json
from time import sleep
import requests

from requests_sse import EventSource, InvalidStatusCodeError, InvalidContentTypeError, MessageEvent

from src import config

from openapi_client.api.default_api import DefaultApi

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

                    self.manageNotification(event)
            except InvalidStatusCodeError:
                pass
            except InvalidContentTypeError:
                pass
            except requests.RequestException:
                pass
            except KeyboardInterrupt:
                exit

    def manageNotification(self, event: MessageEvent):
        if event.type == "notify":
            notificationData = json.loads(event.data)["notification"]
            print("Recevied", notificationData["name"].split('/')[-1])
            iouId = notificationData["refId"]
            paymentAmount = notificationData["arguments"][0]["value"]
            remainderAmount = notificationData["arguments"][1]["value"]
            
            sleep(5)

            if remainderAmount == 0:
                self.api.iou_confirm_repayment(iouId)
            else:
                self.api.iou_acknowledge_payment(iouId)

            print("Payment acknowledged: ", paymentAmount)
        
        else: 
            print(event)
        
