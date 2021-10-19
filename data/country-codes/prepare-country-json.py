import pandas as pd
import json

countries = pd.read_csv('country_codes.csv', usecols=['code', 'name_en'])

country_dict = {}

for item in countries.itertuples():
    country_dict.update({item[1] : item[2]})

with open("country_codes.json", "w") as outfile:
    json.dump(country_dict, outfile)
