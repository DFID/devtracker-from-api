# Pulling Country Codes CSV File

The country codes csv file is pulled from [here](https://codeforiati.org/country-codes/country_codes.csv). This list is scraped from the [iso.org Alpha-2 code list](https://www.iso.org/obp/ui/#iso:pub:PUB500001:en)

If a new country code is added or updated, please pull the CSV file from the above link and save it under this directory. After that, please run the python script prepare-country-json.py to generate the country code and name key/val pair list json file which will be used by DevTracker.