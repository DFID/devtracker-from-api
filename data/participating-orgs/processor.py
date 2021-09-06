import pandas as pd
import json
import os

print("Processing started..")
data_from_json = {}
participating_orgs = {}
with open('orgList.json') as json_data:
    data_from_json = json.load(json_data)
for data in data_from_json['response']['docs']:
    tempOrgList = data['participating_org']
    for i in tempOrgList:
        tt = {}
        tt = json.loads(i)
        if tt['ref'] not in participating_orgs.keys() and tt['ref'] is not None:
            participating_orgs[tt['ref']] = tt['narrative']
formattedJson = json.dumps(participating_orgs)
with open("processed_orgList.json", "w") as outfile:
    outfile.write(formattedJson)

print("Processing Completed!")