import pandas as pd
import json
import os
import requests

with open('calls.csv') as apiCalls:
    line = apiCalls.readline()
    while line:
        response = requests.get(line)
        if response.status_code != 200:
            print(500)
        else:
            print(response.status_code)
        line = apiCalls.readline()