import pandas as pd
import json
import os
import requests

headings = ['Date','Operation','Path','ApiCall', 'Response']
cols = [0,1,2,3, 4]
urlList =  pd.read_csv('api_out.tsv', sep='\t', header=None, engine='python', usecols = cols, names= headings, delimiter='\t')

print(urlList)
mainL = pd.DataFrame(urlList)
for i in mainL.index:
    response = requests.get(mainL['ApiCall'][i])
    if response.status_code != 200:
        print(mainL['ApiCall'][i])
    else:
        print(i, '--', response.status_code)