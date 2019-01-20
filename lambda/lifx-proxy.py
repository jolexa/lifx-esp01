#!/usr/bin/env python
import os
from botocore.vendored import requests


# This function is going to be invoked by a http request to API GW
# The request payload will include the state (power, color, brightness)
# The request payload will include the selector as well
# This lambda function is a simple proxy that has the auth to call the LIFX API
# with whatever parameters are sent to it.
def handler(event, context):
    print(event)
    # build the url
    # url = "https://api.lifx.com/v1/lights/{}".format(selector)
    # r = requests.put(url+'/state', data=build_payload('on'), headers=headers)
    # print(r.json())
