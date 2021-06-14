import pandas as pd
import json
import os
import requests
import math
from deepdiff import DeepDiff
import sys

print ("Importing data..")

fts_urls = {
        "solr_activities": 'https://iatidatastore.iatistandard.org//search/activity/?q=hierarchy:1 AND activity_status_code:2 AND participating_org_ref:GB-* AND  (title_narrative:"Ethiopia" OR description_narrative:"Ethiopia" OR iati_identifier:"Ethiopia" OR transaction_description_narrative:"Ethiopia" OR reporting_org_ref:"Ethiopia")&rows=3000&fl=iati_identifier, reporting_org_ref, reporting_org_narrative, title_narrative, description_narrative, activity_date_iso_date, activity_date_start_actual, activity_date_end_planned, activity_status_code, humanitarian, tag_code, tag&start=0',
        "oipa_activities": 'https://devtracker.fcdo.gov.uk/api/activities/?hierarchy=1&format=json&fields=activity_dates,aggregations,descriptions,activity_status,iati_identifier,url,title,reporting_organisation,activity_plus_child_aggregation&q=Ethiopia&activity_status=2&ordering=-activity_plus_child_budget_value&page_size=20',
        "solr_sectors": 'https://iatidatastore.iatistandard.org/search/activity/?facet=on&facet.field=sector_code&facet.limit=-1&facet.mincount=1&q=activity_status_code:2 AND hierarchy:1 AND participating_org_ref:GB-* AND  (title_narrative:"Ethiopia" OR description_narrative:"Ethiopia" OR iati_identifier:"Ethiopia" OR transaction_description_narrative:"Ethiopia" OR reporting_org_ref:"Ethiopia")',
        "oipa_sectors": 'https://devtracker.fcdo.gov.uk/api/activities/aggregations/?format=json&group_by=sector&aggregations=count&q=Ethiopia&activity_status=2&hierarchy=1',
        "solr_implementing": 'https://iatidatastore.iatistandard.org/search/activity/?facet=on&facet.field=participating_org_ref&facet.limit=-1&facet.mincount=1&q=activity_status_code:2 AND hierarchy:1 AND participating_org_ref:GB-* AND participating_org_role:4 AND  (title_narrative:"Ethiopia" OR description_narrative:"Ethiopia" OR iati_identifier:"Ethiopia" OR transaction_description_narrative:"Ethiopia" OR reporting_org_ref:"Ethiopia")',
        "oipa_implementing": 'https://devtracker.fcdo.gov.uk/api/activities/aggregations/?format=json&group_by=participating_organisation&aggregations=count&q=Ethiopia&hierarchy=1&activity_status=2'
    }

oipa_activities = {}
oipa_response = requests.get(fts_urls['oipa_activities'], verify=False, timeout=100)
oipa_data = oipa_response.json()
oipa_activities['count'] = oipa_data['count']
page_count = math.ceil(oipa_activities['count']/20)

offset = 1
while offset <= page_count:
    oipa_response = requests.get(fts_urls['oipa_activities'] + '&page=' + str(offset))
    oipa_data = oipa_response.json()
    for activity in oipa_data['results']:
         oipa_activities[activity['iati_identifier']] = activity['title']['narratives'][0]['text']
    print('Request completed:'+ str(offset))
    offset = offset + 1


solr_activities = {}
solr_response = requests.get(fts_urls['solr_activities'])
solr_data = solr_response.json()
solr_activities['count'] = solr_data['response']['numFound']
for activity in solr_data['response']['docs']:
    solr_activities[activity['iati_identifier']] = activity['title_narrative']

diff = DeepDiff(oipa_activities, solr_activities)

not_present_activities_oipa = []
not_present_activities_solr = []

for activity in solr_activities:
    if activity not in oipa_activities.keys():
        not_present_activities_oipa.append(activity)

sys.stdout = open("not-found-list-in-oipa.json", "w")

print(not_present_activities_oipa)

sys.stdout.close()

for activity in oipa_activities:
    if activity not in solr_activities.keys():
        not_present_activities_solr.append(activity)

sys.stdout = open("not-found-list-in-solr.json", "w")

print(not_present_activities_solr)

sys.stdout.close()

sys.stdout = open("solr-activities.json", "w")

print(solr_activities)

sys.stdout.close()

sys.stdout = open("oipa-activities.json", "w")

print(oipa_activities)

sys.stdout.close()

sys.stdout = open("comparison-report-activities.json", "w")

print(diff)

sys.stdout.close()

#Sector data testing

solr_sectors = {}
oipa_sectors = {}

oipa_response = requests.get(fts_urls['oipa_sectors'], verify=False, timeout=100)
oipa_data = oipa_response.json()
oipa_sectors['count'] = oipa_data['count']
oipa_sectors['sectors'] = []
for sector in oipa_data['results']:
    oipa_sectors['sectors'].append(sector['sector']['code'])

solr_response = requests.get(fts_urls['solr_sectors'])
solr_data = solr_response.json()
solr_sectors['count'] = len(solr_data['facet_counts']['facet_fields']['sector_code'])/2
solr_sectors['sectors'] = []
for i, sector in enumerate(solr_data['facet_counts']['facet_fields']['sector_code']):
    if i/2 == 0:
        solr_sectors['sectors'].append(sector)

diff = DeepDiff(oipa_sectors, solr_sectors)

sys.stdout = open("comparison-report-sectors.json", "w")

print(diff)

sys.stdout.close()

sys.stdout = open("comparison-report-sectors-not-in-solr.json", "w")

print(set(oipa_sectors['sectors']) - set(solr_sectors['sectors']))

sys.stdout.close()

sys.stdout = open("comparison-report-sectors-not-in-oipa.json", "w")

print(set(solr_sectors['sectors']) - set(oipa_sectors['sectors']))

sys.stdout.close()


#participating organisation list comparison
solr_orgs = {}
oipa_orgs = {}

oipa_response = requests.get(fts_urls['oipa_implementing'], verify=False, timeout=100)
oipa_data = oipa_response.json()
for org in oipa_data['results']:
    if org['participating_organisation_ref'] != '':
        oipa_orgs[org['participating_organisation_ref']] = org['participating_organisation']
oipa_orgs['count'] = len(oipa_orgs)

solr_response = requests.get(fts_urls['solr_implementing'])
solr_data = solr_response.json()
solr_orgs['count'] = len(solr_data['facet_counts']['facet_fields']['participating_org_ref'])/2
solr_orgs['orgs'] = []
for i, org in enumerate(solr_data['facet_counts']['facet_fields']['participating_org_ref']):
    if i/2 == 0:
        solr_orgs[org.upper()] = org.upper()

diff = DeepDiff(oipa_orgs, solr_orgs)

sys.stdout = open("comparison-report-orgs.json", "w")

print(diff)

sys.stdout.close()

# sys.stdout = open("comparison-report-orgs-not-in-solr.json", "w")

# print(set(oipa_orgs['orgs']) - set(solr_orgs['orgs']))

# sys.stdout.close()

# sys.stdout = open("comparison-report-orgs-not-in-oipa.json", "w")

# print(set(solr_orgs['orgs']) - set(oipa_orgs['orgs']))

# sys.stdout.close()




not_present_orgs_oipa = []
not_present_orgs_solr = []

for org in solr_orgs:
    if org not in oipa_orgs.keys():
        not_present_orgs_oipa.append(org)

sys.stdout = open("not-found-org-list-in-oipa.json", "w")

print(not_present_orgs_oipa)

sys.stdout.close()

for org in oipa_orgs:
    if org not in solr_orgs.keys():
        not_present_orgs_solr.append(org)

sys.stdout = open("not-found-org-list-in-solr.json", "w")

print(not_present_orgs_solr)

sys.stdout.close()