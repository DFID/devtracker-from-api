#dotenv is used to load the sensitive environment variables for devtracker.

require 'dotenv'
Dotenv.load('/etc/platform.conf')

require 'sinatra'
require 'json'
require 'rest-client'
require 'active_support/all'
require 'kramdown'
require 'pony'
require 'money'
require 'benchmark'
require 'eventmachine'
require 'em-synchrony'
require "em-synchrony/em-http"
require 'oj'
require 'rss'
require "sinatra/json"
require "action_view"
require 'csv'
require "sinatra/cookies"
require "cgi"

#helpers path
require_relative 'helpers/formatters.rb'
require_relative 'helpers/oipa_helpers.rb'
require_relative 'helpers/codelists.rb'
require_relative 'helpers/lookups.rb'
require_relative 'helpers/common_helpers.rb'
require_relative 'helpers/project_helpers.rb'
require_relative 'helpers/sector_helpers.rb'
require_relative 'helpers/country_helpers.rb'
require_relative 'helpers/document_helpers.rb'
require_relative 'helpers/common_helpers.rb'
require_relative 'helpers/results_helper.rb'
require_relative 'helpers/JSON_helpers.rb'
require_relative 'helpers/filters_helper.rb'
require_relative 'helpers/search_helper.rb'
require_relative 'helpers/input_sanitizer.rb'
require_relative 'helpers/region_helpers.rb'
require_relative 'helpers/recaptcha_helper.rb'
require_relative 'helpers/solr_helper.rb'

#Helper Modules
include CountryHelpers
include Formatters
include SectorHelpers
include ProjectHelpers
include CommonHelpers
include ResultsHelper
include FiltersHelper
include SearchHelper
include InputSanitizer
include RegionHelpers
include RecaptchaHelper
include SolrHelper

# Developer Machine: set global settings
#set :oipa_api_url, 'https://fcdo-direct-indexing.iati.cloud/search/'#'https://fcdo.iati.cloud/search/'#'https://fcdo-direct-indexing.iati.cloud/search/'#'https://devtracker.fcdo.gov.uk/api/'
# set :oipa_api_url, 'https://devtracker-entry.oipa.nl/api/'
# set :oipa_api_url, 'https://fcdo-staging.iati.cloud/search/'
# set :oipa_api_url, 'https://fcdo-direct-indexing.iati.cloud/search/'
#set :bind, '0.0.0.0' # Allows for vagrant pass-through whilst debugging

# Server Machine: set global settings to use varnish cache
set :oipa_api_url, 'http://127.0.0.1:6081/search/'
set :prod_api_url, 'https://fcdo.iati.cloud'
set :dev_api_url, 'https://fcdo-staging.iati.cloud'


#ensures that we can use the extension html.erb rather than just .erb
Tilt.register Tilt::ERBTemplate, 'html.erb'
Money.locale_backend = :i18n
Money.default_currency = "GBP"

#####################################################################
#  Common Variable Assingment
#####################################################################

set :current_first_day_of_financial_year, first_day_of_financial_year(DateTime.now)
set :current_last_day_of_financial_year, last_day_of_financial_year(DateTime.now)
set :goverment_department_ids, 'GB-GOV-15,GB-GOV-9,GB-GOV-6,GB-GOV-2,GB-GOV-1,GB-1,GB-GOV-3,GB-GOV-13,GB-GOV-7,GB-6,GB-10,GB-GOV-10,GB-9,GB-GOV-8,GB-GOV-5,GB-GOV-12,GB-COH-RC000346,GB-COH-03877777,GB-GOV-24'
#set :goverment_department_ids, 'GB-GOV-1,GB-1'
set :google_recaptcha_publicKey, ENV["GOOGLE_PUBLIC_KEY"]
set :google_recaptcha_privateKey, ENV["GOOGLE_PRIVATE_KEY"]

set :raise_errors, false
set :show_exceptions, false
set :log_api_calls, false

set :devtracker_page_title, ''
#####################################################################
#  HOME PAGE
#####################################################################

get '/' do  #homepage
	#read static data from JSON files for the front page
	top5results = JSON.parse(File.read('data/top5results.json'))
	top5countries = ''
	Benchmark.bm(7) do |x|
		x.report("Loading Time: ") {
			if (!canLoadFromCache('top5Countries'))
				storeCacheData(get_top_5_countriesv2(), 'top5Countries')
				top5countries = getCacheData('top5Countries')
			else
				top5countries = getCacheData('top5Countries')
			end
		   #oipa v3.1
		}
   end
	## cache storing ends here
  	odas = Oj.load(File.read('data/odas.json'))
  	odas = odas.first(10)
  	settings.devtracker_page_title = ''
  	# Example of setting up a cookie from server end
  	# response.set_cookie('my_cookie', 'value_of_cookie')
	what_we_do = ''
	if (!canLoadFromCache('what_we_do'))
		## logic
		## get budget data, then check if they fall within date range
		## do a summation of the budget amount within date range
		## pick dac5 sector code and then get the underlying high level sector code
		## if the sector is present, add the new budget info to this sector
		## Else create a new ref to the high level sector code and add
		## budget value starting from 0
		## pick budget percentage for each dac5 sector code2
		## calculate the budget amount against that perentage and add it to
		## the high level related sector code
		newApiCall = settings.oipa_api_url + "activity?q=participating_org_ref:GB-GOV-* AND reporting_org_ref:(#{settings.goverment_department_ids.gsub(","," OR ")}) AND budget_period_start_iso_date:[#{settings.current_first_day_of_financial_year}T00:00:00Z TO *] AND budget_period_end_iso_date:[* TO #{settings.current_last_day_of_financial_year}T00:00:00Z]&fl=iati_identifier,budget_value,recipient_country_code,recipient_region_code,budget_period_start_iso_date,budget_period_end_iso_date,sector_code,sector_percentage,&rows=50000"
		pulledData = RestClient.get newApiCall
		storeCacheData(high_level_sector_listv2(pulledData, 'top_five_sectors'), 'what_we_do')
		what_we_do = getCacheData('what_we_do')
	else
		what_we_do = getCacheData('what_we_do')
	end
	whatWeDoTotal = what_we_do.first['budget']
	top5countries = top5countries.select{|i| i.has_key?('budget')}
	top5countries = top5countries.sort_by{|val| -val['budget'].to_f}
	top5CountryTotal = top5countries.first['budget']
	activiteProjectCount = JSON.parse(RestClient.get settings.oipa_api_url + "activity/?q=reporting_org_ref:(#{settings.goverment_department_ids.gsub(","," OR ")}) AND hierarchy:1 AND activity_status_code:2&rows=1&fl=iati_identifier")['response']['numFound'].to_i

	erb :'index',
 		:layout => :'layouts/landing', 
 		:locals => {
 			top_5_countries: top5countries.first(10), 
 			what_we_do: what_we_do,
 			what_we_achieve: top5results,
 			odas: odas,
 			oipa_api_url: settings.oipa_api_url,
			whatWeDoTotal: whatWeDoTotal,
			top5CountryTotal: top5CountryTotal,
			activiteProjectCount: activiteProjectCount
 		}
end

get '/total_spend/?' do
	if (!canLoadFromCache('totalGlobalSpend'))
		storeCacheData(get_total_spend(), 'totalGlobalSpend')
		totalSpend = getCacheData('totalGlobalSpend')
	else
		totalSpend = getCacheData('totalGlobalSpend')
	end
	totalSpend = format_billion_stg(totalSpend.to_f)
	json :output => totalSpend
end

############## RUBY APP LEVEL CACHING OF DATA######################
def canLoadFromCache(fileName)
	if File.exists?('data/cache/'+fileName+'.json')
		data = JSON.parse(File.read('data/cache/'+fileName+'.json'))
		updatedDate = data['updatedDate'].to_date
		updatedDate = updatedDate.next_day(7)
		if (DateTime.now.to_date <= updatedDate)
			puts 'date time check passed and sending true'
			return true
		else
			puts 'date time check failed and sending false'
			return false
		end
	else
		puts 'file does not exist, sending false'
		return false
	end
end

def storeCacheData(data, fileName)
	tempData = {}
	tempData['updatedDate'] = DateTime.now.to_date
	tempData['data'] = data
	File.open('data/cache/'+fileName+'.json', "w") { |f| f.puts tempData.to_json }
end

def getCacheData(fileName)
	data = JSON.parse(File.read('data/cache/'+fileName+'.json'))
	data['data']
end

####################################################################


#####################################################################
#  COUNTRY PAGES
#####################################################################

# Country summary page
get '/countries/:country_code/?' do |n|
	n = sanitize_input(n,"p").upcase
	country = ''
	results = ''
	if (!canLoadFromCache('country_'+n))
		storeCacheData(get_country_detailsv2(n), 'country_'+n)
		country = getCacheData('country_'+n)
	else
		country = getCacheData('country_'+n)
	end
	countryYearWiseBudgets = ''
	countrySectorGraphData = ''
	newtempActivityCount = 'activity?q=activity_status_code:2 AND hierarchy:1 AND participating_org_ref:GB-GOV-* AND reporting_org_ref:('+settings.goverment_department_ids.gsub(","," OR ")+') AND recipient_country_code:('+n+')&fl=sector_code,sector_percentage,sector_narrative,sector,recipient_country_code,recipient_country_name,recipient_country_percentage,recipient_country,recipient_region_code,recipient_region_name,recipient_region_percentage,recipient_region&rows=1'
	tempActivityCount = Oj.load(RestClient.get  api_simple_log(settings.oipa_api_url + newtempActivityCount))['response']['numFound']
	if n == 'UA2'
		tempActivityCount = 0
	end
	results = get_country_results(n)
	#----- Following project count code needs to be deprecated before merging with main solr branch work ----------------------
	country['totalProjects'] = Oj.load(RestClient.get  api_simple_log(settings.oipa_api_url + 'activity?q=participating_org_ref:GB-GOV-* AND reporting_org_ref:('+settings.goverment_department_ids.gsub(","," OR ")+') AND recipient_country_code:('+n+') AND hierarchy:1 AND activity_status_code:2&fl=iati_identifier&rows=1'))['response']['numFound']

	ogds = Oj.load(File.read('data/OGDs.json'))
	topSixResults = pick_top_six_results(n)
	#Geo Location data of country
	geoJsonData = getCountryBounds(n)
	# Get a list of map markers
	mapMarkers = getCountryMapMarkers(n)
  	settings.devtracker_page_title = 'Country ' + country['name'] + ' Summary Page'
	json_link = ''
	if request.url.start_with?('https://devtracker.')
		json_link = json_link + settings.prod_api_url
	else
		json_link = json_link + settings.dev_api_url
	end
	json_link = json_link + '/search/activity/?q=recipient_country_code:'+n+' AND reporting_org_ref:GB-GOV-* AND hierarchy:1&format='
	erb :'countries/country', 
		:layout => :'layouts/layout',
		:locals => {
 			country: country,
 			results: results,
 			topSixResults: topSixResults,
 			oipa_api_url: settings.oipa_api_url,
 			activityCount: tempActivityCount,
 			countryGeoJsonData: geoJsonData,
			mapMarkers: mapMarkers,
			active_link: 'aidByLoc',
			active_sub_link: 'countrySummary',
			json_url_link: json_link
 		}
end
## country summary page related api calls
get '/country-implementing-org-list/:country_code/:activity_count/?' do
	n = sanitize_input(params[:country_code],"p").upcase
	count = sanitize_input(params[:activity_count],"p")
	json :output => getCountryLevelImplOrgs(n,count)
end

get '/country-sector-graph-data/:country_code/?' do |n|
	n = sanitize_input(n,"p").upcase
	country = ''
	json :output => get_country_sector_graph_data_jsCompatibleV2(n)
end

get '/region-sector-graph-data/:country_code/?' do |n|
	n = sanitize_input(n,"p").upcase
	country = ''
	json :output => get_region_sector_graph_data_jsCompatibleV2(n)
end

get '/country-budget-bar-graph-data/:country_code/?' do |n|
	n = sanitize_input(n,"p").upcase
	json :output => budgetBarGraphDataDv3(n)
end 
##
# solr route
get '/countries/:country_code/projects/?' do |n|
	n = sanitize_input(n, "p")
	query = '('+n+')'
	filters = prepareFilters(query.to_s, 'C')
	response = solrResponse(query, 'AND activity_status_code:(2)', 'C', 0, '', '')
	if(response['numFound'].to_i > 0)
		response = addTotalBudgetWithCurrency(response)
	end
	settings.devtracker_page_title = 'Search Results For : ' + query
	projectData = ''
	country = get_country_code_name(n)
  	settings.devtracker_page_title = 'Country ' + country['name'] + ' Programmes Page'
	erb :'countries/projects', 
		:layout => :'layouts/layout',
		:locals => {
			oipa_api_url: settings.oipa_api_url,
	 		country: country,
	 		total_projects: response['numFound'],
			query: query,
			filters: filters,
			response: response,
			solrConfig: Oj.load(File.read('data/solr-config.json')),
			activityStatus: Oj.load(File.read('data/activity_status.json')),
			searchType: 'C',
			breadcrumbURL: '/location/country',
			breadcrumbText: 'Aid by Location'
	 	}
end

#####################################################################
#  GLOBAL PAGES
#####################################################################

#Global Project List Page
get '/global/:global_code/projects/?' do |n|
	n = sanitize_input(n,"p")
	countryAllProjectFilters = get_static_filter_list()
	region = {}
	if n == 'ZZ'
		region[:code] = "ZZ"
		region[:name] = "Multilateral Organisation"
	elsif n == 'NS'
		region[:code] = "NS"
		region[:name] = "Non Specific Country"
	else
		region[:code] = ""
		region[:name] = "ALL"
	end
	#getRegionProjects = get_region_projects(region[:code])
	getRegionProjects = generate_project_page_data(generate_api_list('R',region[:code],"2"))
	settings.devtracker_page_title = 'Global '+region[:name]+' Programme Page'
	erb :'regions/projects', 
		:layout => :'layouts/layout',
		:locals => {
			oipa_api_url: settings.oipa_api_url,
	 		region: region,
	 		total_projects: getRegionProjects['projects']['count'],
	 		projects: getRegionProjects['projects']['results'],
	 		countryAllProjectFilters: countryAllProjectFilters,
	 		highLevelSectorList: getRegionProjects['highLevelSectorList'],
	 		budgetHigherBound: getRegionProjects['project_budget_higher_bound'],
	 		actualStartDate: getRegionProjects['actualStartDate'],
 			plannedEndDate: getRegionProjects['plannedEndDate'],
 			documentTypes: getRegionProjects['document_types'],
 			implementingOrgTypes: getRegionProjects['implementingOrg_types'],
 			reportingOrgTypes: getRegionProjects['reportingOrg_types']
		}	 			
end

#####################################################################
#  REGION PAGES
#####################################################################
# Region summary page
get '/regions/:region_code/?' do |n|
	n = sanitize_input(n,"p")
    region = get_region_detailsv2(n)
  	settings.devtracker_page_title = 'Region '+region[:name]+' Summary Page'
	erb :'regions/region', 
		:layout => :'layouts/layout',
		:locals => {
			oipa_api_url: settings.oipa_api_url,
 			region: region,
			regionYearWiseBudgets: get_country_region_yearwise_budget_graph_datav2(RestClient.get api_simple_log(settings.oipa_api_url + 'activity/?q=recipient_region_code:'+n+' AND reporting_org_ref:('+settings.goverment_department_ids.gsub(","," OR ")+') &fl=budget_value,default-currency,budget_period_start_iso_date,budget_period_end_iso_date,budget.period-start.quarter,budget.period-end.quarter')),
 			mapMarkers: getRegionMapMarkersv2(region[:code]),
 		}
end

#Region Project List Page
get '/regions/:region_code/projects/?' do |n|
	n = sanitize_input(n, "p")
	query = '('+n+')'
	filters = prepareFilters(query.to_s, 'R')
	response = solrResponse(query, 'AND activity_status_code:(2)', 'R', 0, '', '')
	if(response['numFound'].to_i > 0)
		response = addTotalBudgetWithCurrency(response)
	end
	countryAllProjectFilters = get_static_filter_list()
	region = get_region_code_name(n)
  	settings.devtracker_page_title = 'Region '+region[:name]+' Programmes Page'
	if n.to_i == 998
		breadcrumbURL = '/location/global'
	else
		breadcrumbURL = '/location/regional'
	end
	erb :'regions/projects', 
		:layout => :'layouts/layout',
		:locals => {
			oipa_api_url: settings.oipa_api_url,
	 		region: region,
	 		total_projects: response['numFound'],
	 		query: query,
			filters: filters,
			response: response,
			solrConfig: Oj.load(File.read('data/solr-config.json')),
			activityStatus: Oj.load(File.read('data/activity_status.json')),
			searchType: 'R',
			breadcrumbURL: breadcrumbURL,
			breadcrumbText: 'Aid by Location'
		}	 			
end

#####################################################################
#  PROJECTS PAGES
#####################################################################

# Project summary page
get '/projects/*/summary' do
	n = ERB::Util.url_encode (params['splat'][0]).to_s
	#n = sanitize_input(n,"p")
	check_if_project_exists(n)
	# get the project data from the API
  	project = get_h1_project_detailsv2(n)
  	participatingOrgList = get_participating_organisationsv2(project)
  	#get the country/region data from the API
  	countryOrRegion = get_country_or_regionv2(n)
	spendToDate = spendToDatev2(n)
	programmeBudget = 0
	if(project.has_key?('activity_plus_child_aggregation_budget_value_gbp'))
		programmeBudget = programmeBudget + project['activity_plus_child_aggregation_budget_value_gbp'].to_f
	elsif(project.has_key?('related_budget_value'))
		project['related_budget_value'].each do |b|
			programmeBudget = programmeBudget + b.to_f
		end
	elsif(project.has_key?('activity_aggregation_budget_value_gbp'))
		programmeBudget = programmeBudget + project['activity_aggregation_budget_value_gbp'].to_f
	else
		if project.has_key?('budget_value')
			project['budget_value'].each do |budget|
				programmeBudget = programmeBudget + budget
			end
		end
	end
	if(!project['reporting_org_ref'].to_s == 'GB-GOV-1')
		if(project.has_key?('activity_aggregation_incoming_funds_value_gbp'))
			programmeBudget = programmeBudget + project['activity_aggregation_incoming_funds_value_gbp'].to_f
		end
		if(project.has_key?('activity_aggregation_commitment_value_gbp'))
			programmeBudget = programmeBudget + project['activity_aggregation_commitment_value_gbp'].to_f
		end
	end
  	#get project sectorwise graph  data
  	projectSectorGraphData = get_project_sector_graph_datav2(n)
  	settings.devtracker_page_title = 'Programme '+project['iati_identifier']
	erb :'projects/summary', 
		:layout => :'layouts/layout',
		 :locals => {
			projectId: n,
		 	oipa_api_url: settings.oipa_api_url,
 			project: project,
 			countryOrRegion: countryOrRegion,	 					 			
 			projectSectorGraphData: projectSectorGraphData,
 			participatingOrgList: participatingOrgList,
 			policyMarkers: get_policy_markersv2(project),
 			mapMarkers: getProjectMapMarkersv2(project),
			spendToDate: spendToDate,
			programmeBudget: programmeBudget
 		}
end

# Project documents page
get '/projects/*/documents/?' do
	n = ERB::Util.url_encode (params['splat'][0]).to_s
	check_if_project_exists(n)
	# get the project data from the API
	project = get_h1_project_documents(n)
	doc_categories = Oj.load(File.read('data/doc_category_list.json'))
  	settings.devtracker_page_title = 'Programme '+project['iati_identifier']+' Documents'
	erb :'projects/documents', 
		:layout => :'layouts/layout',
		:locals => {
			oipa_api_url: settings.oipa_api_url,
 			project: project,
			cateogies: doc_categories,
 		}
end

#Project transactions page
get '/projects/*/transactions/?' do
	n = ERB::Util.url_encode (params['splat'][0]).to_s
	check_if_project_exists(n)
	# get the project data from the API
	project = get_h1_project_detailsv2(n)
	
  	settings.devtracker_page_title = 'Programme '+project['iati_identifier']+' Transactions'
	erb :'projects/transactions', 
		:layout => :'layouts/layout',
		:locals => {
			oipa_api_url: settings.oipa_api_url,
			project: project,
 		}
end

#Project transactions page
get '/projects/*/components/?' do
	n = ERB::Util.url_encode (params['splat'][0]).to_s
	check_if_project_exists(n)
	# get the project data from the API
	project = get_h1_project_detailsv2(n)

  	settings.devtracker_page_title = 'Programme '+project['iati_identifier']+' Transactions'
	erb :'projects/components', 
		:layout => :'layouts/layout',
		:locals => {
			oipa_api_url: settings.oipa_api_url,
			project: project
 		}
end
######################################################################
################## PROJECT  PAGE RELATED API CALLS ###################
######################################################################
post 'get-participating-orgs' do
	project = sanitize_input(params['data']['project'].to_s,"newId")

	json :output => get_participating_organisations(project)
end

post '/transaction-details' do
	project = sanitize_input(params['data']['projectID'].to_s,"newId")
	transactionType = sanitize_input(params['data']['transactionType'].to_s, "a")

	json :output => get_transaction_details(project,transactionType)
end

get '/transaction-count/*?' do
	n = ERB::Util.url_encode (params['splat'][0]).to_s
	json :output => get_transaction_countv2(n)
end

post '/transaction-details-pagev2' do
	project = sanitize_input(params['data']['projectID'].to_s,"newId")
	transactionType = sanitize_input(params['data']['transactionType'].to_s, "a")
	resultCount = 20
	nextPage = sanitize_input(params['data']['nextPage'].to_s, "a")
	json :output => get_transaction_details_pagev2(project,transactionType, nextPage, resultCount)
end

post '/transaction-total' do
	project = sanitize_input(params['data']['project'].to_s,"newId")
	transactionType = sanitize_input(params['data']['transactionType'].to_s, "a")
	currency = sanitize_input(params['data']['currency'].to_s, "newId")
	#json :output => get_transaction_total(project,transactionType, currency)
	json :output => get_transaction_totalv2(project,transactionType)
end

get '/component-list/*?' do
	n = ERB::Util.url_encode (params['splat'][0]).to_s
	oipa = RestClient.get  api_simple_log(settings.oipa_api_url + "activity/?q=iati_identifier:#{n}&fl=related_activity_ref&rows=1")
    project = JSON.parse(oipa)['response']['docs'].first
	json :output => project['related_activity_ref']
end

# Get yearly budget for H1 Activity from the API
get '/project-yearwise-budget/*?' do
	n = ERB::Util.url_encode (params['splat'][0]).to_s
	projectYearWiseBudgets= get_project_yearwise_budgetv2(n)
	json :output=> projectYearWiseBudgets
end

# Convert number to proper currency data
post '/number-to-currency' do
	number = sanitize_input(params['data']['number'].to_s,"a")
	currency = sanitize_input(params['data']['currency'].to_s, "newId")
	begin
		data = Money.new(number.to_f.round(0)*100, currency).format(:no_cents_if_whole => true,:sign_before_symbol => false)
	rescue
		data = "£#{number}"
	end
	json :output=> data
end

# Get total project budget
get '/total-project-budget/*?' do
	n = ERB::Util.url_encode (params['splat'][0]).to_s
	project = get_h1_project_detailsv2(n)
	projectYearWiseBudgets= get_project_yearwise_budget(n)
	totalProjectBudget=get_sum_budget(projectYearWiseBudgets).to_f
	begin
		data = Money.new(totalProjectBudget.round(0)*100, if project['activity_plus_child_aggregation']['activity_children']['budget_currency'].nil? then project['default_currency']['code'] else project['activity_plus_child_aggregation']['activity_children']['budget_currency'] end).format(:no_cents_if_whole => true,:sign_before_symbol => false)
	rescue
		data = "£#{totalProjectBudget}"
	end
	json :output=> data
end

get '/total-project-budgetv2/*?' do
	n = ERB::Util.url_encode (params['splat'][0]).to_s
	programmeBudgets = RestClient.get api_simple_log(settings.oipa_api_url + "activity/?q=iati_identifier:#{n}*&fl=budget_value,default-currency&rows=200")
	programmeBudgets = JSON.parse(programmeBudgets)['response']['docs']
	totalBudget = 0
	programmeBudgets.each do |project|
		if project.has_key?('budget_value')
			project['budget_value'].each do |budget|
				totalBudget = totalBudget + budget
			end
		end
	end
	begin
		data = Money.new(totalBudget.round(0)*100, if programmeBudgets.first.has_key?('default-currency') then programmeBudgets.first['default-currency'] else 'GBP' end).format(:no_cents_if_whole => true,:sign_before_symbol => false)
	rescue
		data = "£#{totalBudget}"
	end
	json :output=> data
end

get '/project-details/*?' do
	n = ERB::Util.url_encode (params['splat'][0]).to_s
	#oipa = RestClient.get api_simple_log(settings.oipa_api_url + "activities/#{n}/?format=json&fields=iati_identifier,title,description,activity_date")
	oipa = RestClient.get api_simple_log(settings.oipa_api_url + "activity/?q=iati_identifier:#{n}&fl=iati_identifier,title_narrative,description_narrative,activity_date_type,activity_date_iso_date&rows=1")
	oipa = JSON.parse(oipa)['response']['docs'].first
	tempData = {}
	tempData['iati_identifier'] = oipa['iati_identifier']
	tempData['title'] = oipa['title_narrative'].first
	tempData['description'] = oipa['description_narrative'].first
	tempData['activity_date'] = {}
	tempData['activity_dates'] = bestActivityDatev2(oipa)
	json :output=> tempData
end

get '/country-or-region/*?' do
	n = ERB::Util.url_encode (params['splat'][0]).to_s
	json :output=> get_country_or_regionv2(n)
end

# Get the funding projects Count from the API
get '/get-funding-projects/*?' do
	n = ERB::Util.url_encode (params['splat'][0]).to_s
	json :output=> get_funding_project_countv2(n)
end

# Get funded project counts
get '/get-funded-projects/*?' do
	n = ERB::Util.url_encode (params['splat'][0]).to_s
	json :output=> get_funded_project_countv2(n)
end

# projects that are funded by this target project
get '/get-funded-projects-page/:page/*?' do
	n = ERB::Util.url_encode (params['splat'][0]).to_s
	page = ERB::Util.url_encode params[:page].to_s
	json :output=> get_funded_project_details_pagev2(n, page, 20)
end

# projects that are funding this target project
get '/get-funding-projects-details/*?' do
	n = ERB::Util.url_encode (params['splat'][0]).to_s
	json :output=> get_funding_project_detailsv2(n)
end

######################################################################
######################################################################
#Project partners page
get '/projects/*/partners/?' do
	n = ERB::Util.url_encode (params['splat'][0]).to_s
	check_if_project_exists(n)
	# get the project data from the API
	project = get_h1_project_detailsv2(n)

  	settings.devtracker_page_title = 'Programme '+project['iati_identifier']+' Partners'
	erb :'projects/partners',
		:layout => :'layouts/layout',
		:locals => {
			oipa_api_url: settings.oipa_api_url,
			project: project
 		}
end

#####################################################################
#  SECTOR PAGES
#####################################################################
# examples:
# http://devtracker.fcdo.gov.uk/sector/

# High Level Sector summary page
get '/sector/?' do
	# Get the high level sector data from the API
	high_level_sector_list = ''
	if (!canLoadFromCache('high_level_sector_list'))
		newApiCall = settings.oipa_api_url + "activity?q=participating_org_ref:GB-GOV-* AND reporting_org_ref:(#{settings.goverment_department_ids.gsub(","," OR ")}) AND budget_period_start_iso_date:[#{settings.current_first_day_of_financial_year}T00:00:00Z TO *] AND budget_period_end_iso_date:[* TO #{settings.current_last_day_of_financial_year}T00:00:00Z]&fl=iati_identifier,budget_value,recipient_country_code,recipient_region_code,budget_period_start_iso_date,budget_period_end_iso_date,sector_code,sector_percentage,&rows=50000"
		pulledData = RestClient.get newApiCall
		storeCacheData(high_level_sector_listv2(pulledData, 'all_sectors'), 'high_level_sector_list')
		high_level_sector_list = getCacheData('high_level_sector_list')
	else
		high_level_sector_list = getCacheData('high_level_sector_list')
	end
  	settings.devtracker_page_title = 'Sector Page'
  	erb :'sector/index', 
		:layout => :'layouts/layout',
		 :locals => {
		 	oipa_api_url: settings.oipa_api_url,
 			high_level_sector_list: high_level_sector_list,#high_level_sector_list( get_5_dac_sector_data(), "all_sectors", "High Level Code (L1)", "High Level Sector Description")
			active_link: 'sector'
 		}		
end

# Category Page (e.g. Three Digit DAC Sector) 
get '/sector/:high_level_sector_code/?' do
	# Get the three digit DAC sector data from the API
	dac2Code = sanitize_input(params[:high_level_sector_code],"p")
	high_level_sector_list = ''
	fileName = 'sector_dac2_'+dac2Code
	if (!canLoadFromCache(fileName))
		prepSectorCodeFilter = ''
		sectorHierarchy = JSON.parse(File.read('data/sectorHierarchies.json')).select{|s| s['High Level Code (L1)'].to_i == dac2Code.to_i}
		sectorHierarchy.each_with_index do |elem, index|
			if index == sectorHierarchy.length-1
				prepSectorCodeFilter = prepSectorCodeFilter + elem['Code (L3)'].to_s
			else
				prepSectorCodeFilter = prepSectorCodeFilter + elem['Code (L3)'].to_s + ' OR '
			end
		end
		newApiCall = settings.oipa_api_url + "activity?q=participating_org_ref:GB-GOV-* AND reporting_org_ref:(#{settings.goverment_department_ids.gsub(","," OR ")}) AND sector_code:("+prepSectorCodeFilter+") AND budget_period_start_iso_date:[#{settings.current_first_day_of_financial_year}T00:00:00Z TO *] AND budget_period_end_iso_date:[* TO #{settings.current_last_day_of_financial_year}T00:00:00Z]&fl=iati_identifier,budget_value,recipient_country_code,recipient_region_code,budget_period_start_iso_date,budget_period_end_iso_date,sector_code,sector_percentage,&rows=50000"
		pulledData = RestClient.get newApiCall
		#storeCacheData(sector_parent_data_list( settings.oipa_api_url, "category", "Category (L2)", "Category Name", "High Level Code (L1)", "High Level Sector Description", dac2Code, "category"), fileName)
		storeCacheData(sector_parent_data_listv2(pulledData, sectorHierarchy), fileName)
		high_level_sector_list = getCacheData(fileName)
	else
		high_level_sector_list = getCacheData(fileName)
	end
  	settings.devtracker_page_title = 'Sector '+dac2Code+' Page'
  	erb :'sector/categories', 
		:layout => :'layouts/layout',
		 :locals => {
		 	oipa_api_url: settings.oipa_api_url,
 			category_list: high_level_sector_list,#sector_parent_data_list( settings.oipa_api_url, "category", "Category (L2)", "Category Name", "High Level Code (L1)", "High Level Sector Description", sanitize_input(params[:high_level_sector_code],"p"), "category")
			active_link: 'sector'
		}		
end

# List of all the High level sector projects (e.g. Three Digit DAC Sector) 

# Sector Page (e.g. Five Digit DAC Sector) 
get '/sector/:high_level_sector_code/categories/:category_code/?' do
	# Get the three digit DAC sector data from the API
	dac2Code = sanitize_input(params[:high_level_sector_code],"p")
	catCode = sanitize_input(params[:category_code],"p")
	high_level_sector_list = ''
	fileName = 'sector_dac2_'+dac2Code+'_'+catCode
	if (!canLoadFromCache(fileName))
		prepSectorCodeFilter = ''
		sectorHierarchy = JSON.parse(File.read('data/sectorHierarchies.json')).select{|s| s['Category (L2)'].to_i == catCode.to_i}
		sectorHierarchy.each_with_index do |elem, index|
			if index == sectorHierarchy.length-1
				prepSectorCodeFilter = prepSectorCodeFilter + elem['Code (L3)'].to_s
			else
				prepSectorCodeFilter = prepSectorCodeFilter + elem['Code (L3)'].to_s + ' OR '
			end
		end
		newApiCall = settings.oipa_api_url + "activity?q=participating_org_ref:GB-GOV-* AND reporting_org_ref:(#{settings.goverment_department_ids.gsub(","," OR ")}) AND sector_code:("+prepSectorCodeFilter+") AND budget_period_start_iso_date:[#{settings.current_first_day_of_financial_year}T00:00:00Z TO *] AND budget_period_end_iso_date:[* TO #{settings.current_last_day_of_financial_year}T00:00:00Z]&fl=iati_identifier,budget_value,recipient_country_code,recipient_region_code,budget_period_start_iso_date,budget_period_end_iso_date,sector_code,sector_percentage,&rows=50000"
		pulledData = RestClient.get newApiCall
		#storeCacheData(sector_parent_data_list( settings.oipa_api_url, "category", "Category (L2)", "Category Name", "High Level Code (L1)", "High Level Sector Description", dac2Code, "category"), fileName)
		storeCacheData(sector_parent_data_dac5(pulledData, sectorHierarchy), fileName)
		#storeCacheData(sector_parent_data_list(settings.oipa_api_url, "sector", "Code (L3)", "Name", "Category (L2)", "Category Name", sanitize_input(params[:high_level_sector_code],"p"), sanitize_input(params[:category_code],"p")), fileName)
		high_level_sector_list = getCacheData(fileName)
	else
		high_level_sector_list = getCacheData(fileName)
	end
  	settings.devtracker_page_title = 'Sector Category '+catCode+' Page'
  	erb :'sector/sectors', 
		:layout => :'layouts/layout',
		 :locals => {
		 	oipa_api_url: settings.oipa_api_url,
 			sector_list: high_level_sector_list,#sector_parent_data_list(settings.oipa_api_url, "sector", "Code (L3)", "Name", "Category (L2)", "Category Name", sanitize_input(params[:high_level_sector_code],"p"), sanitize_input(params[:category_code],"p"))
			active_link: 'sector'
		}
end

#####################################################################
#  COUNTRY REGION & GLOBAL PROJECT MAP PAGES
#####################################################################

#Aid By Location Page
get '/location/country/?' do
  	settings.devtracker_page_title = 'Aid by Location Page'
	fileName = 'map_data'
	map_data = ''
	dfid_complete_country_list = ''
	total_coun_bud_loc = ''
	country_sector_data = ''
	getMaxBudget = ''
	if (!canLoadFromCache('country_sector_data'))
		storeCacheData(generateCountryDatav5(), 'country_sector_data')
		getMainData = getCacheData('country_sector_data')
		map_data = getMainData['map_data']
		storeCacheData(map_data[1].sort_by{|k,val| val['budget']}.reverse!.first[1]['budget'], 'getMaxBudgetCountryLocation')
		country_sector_data = getMainData['countryHash']
		getMaxBudget = getCacheData('getMaxBudgetCountryLocation')
	else
		getMainData = getCacheData('country_sector_data')
		map_data = getMainData['map_data']
		country_sector_data = getMainData['countryHash']
		getMaxBudget = getCacheData('getMaxBudgetCountryLocation')
	end
	erb :'location/country/index', 
		:layout => :'layouts/layout',
		:locals => {
			oipa_api_url: settings.oipa_api_url,
			:dfid_country_map_data => 	map_data[0],
			:dfid_country_stats_data => map_data[1],
			:sectorData => country_sector_data,
			:countryMapData => getCountryBoundsForLocation(map_data[1]),
			:maxBudget => getMaxBudget,
			active_link: 'aidByLoc',
			active_sub_link: 'country',
		}
end

# Aid by Region Page
get '/location/regional/?' do 
  	settings.devtracker_page_title = 'Aid by Region Page'
	  dfid_regional_projects_data = ''
	  generateRegionData = ''
	if (!canLoadFromCache('dfid_regional_projects_data_regions'))
		storeCacheData(dfid_regional_projects_datav2("all"), 'dfid_regional_projects_data_regions')
		dfid_regional_projects_data = getCacheData('dfid_regional_projects_data_regions')
	else
		dfid_regional_projects_data = getCacheData('dfid_regional_projects_data_regions')
	end
	erb :'location/regional/index', 
		:layout => :'layouts/layout',
		:locals => {
			:oipa_api_url => settings.oipa_api_url,
			:dfid_regional_projects_data => dfid_regional_projects_data,
			#:generateRegionData => generateRegionData
			active_link: 'aidByLoc',
			active_sub_link: 'region',
		}
end

# Aid by Global Page
get '/location/global/?' do
	dfid_regional_projects_data = ''
	if (!canLoadFromCache('dfid_regional_projects_data_global'))
		storeCacheData(dfid_regional_projects_datav2("global"), 'dfid_regional_projects_data_global')
		dfid_regional_projects_data = getCacheData('dfid_regional_projects_data_global')
	else
		dfid_regional_projects_data = getCacheData('dfid_regional_projects_data_global')
	end
  	settings.devtracker_page_title = 'Aid by Global Page'
	erb :'location/global/index', 
		:layout => :'layouts/layout',
		:locals => {
			:oipa_api_url => settings.oipa_api_url,
			:dfid_global_projects_data => dfid_regional_projects_data,
			active_link: 'aidByLoc',
			active_sub_link: 'global',
		}
end

#####################################################################
#  SOLR BASED PAGES
#####################################################################

get '/search_p/?' do
	if (!params['query'])
		query= ''
		filters = []
		response = 
		{
			'numFound' => -1,
			'docs' => []
		}
		settings.devtracker_page_title = 'Search Page'
		didYouMeanData = {}
		didYouMeanData['dfidCountryBudgets'] = 0
		didYouMeanData['dfidRegionBudgets'] = 0
	else
		query = params['query']
		activityStatuses = 'AND activity_status_code:(2)'
		filters = prepareFilters(query.to_s, 'F')
		response = solrResponse(query, activityStatuses, 'F', 0, '', '')
		if(response['numFound'].to_i > 0)
			response = addTotalBudgetWithCurrency(response)
		end
		settings.devtracker_page_title = 'Search Results For : ' + query
		didYouMeanQuery = sanitize_input(params['query'],"a")
		didYouMeanData = generate_did_you_mean_data(didYouMeanQuery,'2')
	end
	erb :'search/solrTemplate',
	:layout => :'layouts/layout',
	:locals => 
	{
		oipa_api_url: settings.oipa_api_url,
		query: query,
		filters: filters,
		response: response,
		solrConfig: Oj.load(File.read('data/solr-config.json')),
		activityStatus: Oj.load(File.read('data/activity_status.json')),
		searchType: 'F',
		breadcrumbURL: '',
		breadcrumbText: '',
		fcdoCountryBudgets: didYouMeanData['dfidCountryBudgets'],
 		fcdoRegionBudgets: didYouMeanData['dfidRegionBudgets'],
		isIncludeClosedProjects: 0
	}
end

get '/search/?' do
	redirect '/search_p'
end

post '/search_p/?' do
	#query = params['query']
	query = sanitize_input(params['query'],"newId")
	isIncludeClosedProjects = sanitize_input(params['includeClosedProject'],"newId")
	if(isIncludeClosedProjects.to_i != 1)
		activityStatuses = 'AND activity_status_code:(2)'
	else
		activityStatuses = 'AND activity_status_code:(2 OR 3 OR 4 OR 5)'
	end
	filters = prepareFilters(query.to_s, 'F')
	response = solrResponse(query, activityStatuses, 'F', 0, '', '')
	if(response['numFound'].to_i > 0)
		response = addTotalBudgetWithCurrency(response)
	end
  	settings.devtracker_page_title = 'Search Results For : ' + query
	didYouMeanQuery = sanitize_input(params['query'],"a")
	#didYouMeanData = generate_did_you_mean_data(didYouMeanQuery,'2')
	#erb :'search/solrSearch',
	erb :'search/solrTemplate',
	:layout => :'layouts/layout',
	:locals => 
	{
		oipa_api_url: settings.oipa_api_url,
		query: query,
		filters: filters,
		response: response,
		solrConfig: Oj.load(File.read('data/solr-config.json')),
		activityStatus: Oj.load(File.read('data/activity_status.json')),
		searchType: 'F',
		breadcrumbURL: '',
		breadcrumbText: '',
		fcdoCountryBudgets: nil,#didYouMeanData['dfidCountryBudgets'],
 		fcdoRegionBudgets: nil,#didYouMeanData['dfidRegionBudgets'],
		isIncludeClosedProjects: isIncludeClosedProjects
	}
end

post '/solr-response' do
	query = sanitize_input(params['data']['query'],"newId")
	if params['data']['filters'].strip.length > 1
		filters = 'AND ' + sanitize_input(params['data']['filters'],"newId")
	else
		filters = ''
	end
	searchType = sanitize_input(params['data']['queryType'],"newId")
	startPage = sanitize_input(params['data']['page'],"newId")
	response = solrResponse(query, filters, searchType, startPage, sanitize_input(params['data']['dateRange'],"newId"), sanitize_input(params['data']['sortType'],"newId"))
	if(response['numFound'].to_i > 0)
		response = addTotalBudgetWithCurrency(response)
	end
	json :output => response
end

get '/regions/?' do
	query = '(298 OR 798 OR 89 OR 589 OR 389 OR 189 OR 679 OR 289 OR 380)'
	filters = prepareFilters(query.to_s, 'R')
	response = solrResponse(query, 'AND activity_status_code:(2)', 'R', 0, '', '')
	if(response['numFound'].to_i > 0)
		response = addTotalBudgetWithCurrency(response)
	end
	settings.devtracker_page_title = 'Search Results For : ' + query
	
	region = {}
	region[:code] = "298,798,89,589,389,189,679,289,380"
	region[:name] = "All"
	erb :'search/solrTemplate',
	:layout => :'layouts/layout',
	:locals => 
	{
		oipa_api_url: settings.oipa_api_url,
		query: query,
		filters: filters,
		response: response,
		solrConfig: Oj.load(File.read('data/solr-config.json')),
		region:region,
		total_projects: response['numFound'],
		activityStatus: Oj.load(File.read('data/activity_status.json')),
		searchType: 'R',
		breadcrumbURL: '/location/regional',
		breadcrumbText: 'Aid by Location'
	}
end

get '/global/?' do
	query = '(998)'
	filters = prepareFilters(query.to_s, 'R')
	response = solrResponse(query, 'AND activity_status_code:(2)', 'R', 0, '', '')
	if(response['numFound'].to_i > 0)
		response = addTotalBudgetWithCurrency(response)
	end
	settings.devtracker_page_title = 'Search Results For : ' + query
	region = {}
	region[:name] = 'global'
	#erb :'search/solrRegions',
	erb :'search/solrTemplate',
	:layout => :'layouts/layout',
	:locals => 
	{
		oipa_api_url: settings.oipa_api_url,
		query: query,
		filters: filters,
		response: response,
		solrConfig: Oj.load(File.read('data/solr-config.json')),
		activityStatus: Oj.load(File.read('data/activity_status.json')),
		searchType: 'R',
		breadcrumbURL: '/location/global',
		breadcrumbText: 'Aid by Location',
		region: region
	}
end

get '/department/:dept_id/?' do
	dept_id = sanitize_input(params[:dept_id],"a")
	if dept_id == 'abs'
		redirect '/sector'
	end
	allActivityStatusProjectsCount = 0
	ogds = Oj.load(File.read('data/OGDs.json'))
	deptIdentifier = ''
	if ogds.has_key?(dept_id)
		deptIdentifier = ogds[dept_id]["identifiers"]
	else
		redirect '/department'
	end
	if deptIdentifier == ''
		redirect '/department'
	end
	if(deptIdentifier != 'x')
		query = deptIdentifier
	else
		redirect '/department'
	end
  	settings.devtracker_page_title = ogds[dept_id]["name"]
	query = "(" + deptIdentifier.gsub(","," OR ") + ")"
	filters = prepareFilters(query.to_s, 'O')
	response = solrResponse(query, 'AND activity_status_code:(2)', 'O', 0, '', '')
	if(response['numFound'].to_i > 0)
		response = addTotalBudgetWithCurrency(response)
	end
	erb :'search/solrTemplate',
	:layout => :'layouts/layout',
	:locals => 
	{
		oipa_api_url: settings.oipa_api_url,
		query: query,
		filters: filters,
		response: response,
		solrConfig: Oj.load(File.read('data/solr-config.json')),
		activityStatus: Oj.load(File.read('data/activity_status.json')),
		searchType: 'O',
		breadcrumbURL: '/department',
		breadcrumbText: 'Aid by Department',
		ogd_title: settings.devtracker_page_title
	}
end

get '/sector/:high_level_sector_code/projects/?' do
	highLevelCode = sanitize_input(params[:high_level_sector_code],"p")
	sectorCode = ''
	sectorJsonData = JSON.parse(File.read('data/sectorHierarchies.json'))#map_sector_data()
	sectorJsonData = sectorJsonData.select {|sector| sector['High Level Code (L1)'] == highLevelCode.to_i}
	#Segment
	sectorData = {}
	sectorData['highLevelCode'] = highLevelCode
	sectorData['sectorCode'] = ""
	#Segment
	sectorJsonData.each do |sdata|
		sectorCode.concat(sdata['Code (L3)'].to_s + " OR ")
		sectorData['sectorCode'].concat(sdata['Code (L3)'].to_s + ",")
	end
	#Segment
	sectorData['categoryCode'] = ""
	sectorData['sectorName'] = ""
	#Segment
	query = "(" + sectorCode[0, sectorCode.length - 3] + ")"
	puts query
	filters = prepareFilters(query.to_s, 'S')
	response = solrResponse(query, 'AND activity_status_code:(2)', 'S', 0, '', '')
	if(response['numFound'].to_i > 0)
		response = addTotalBudgetWithCurrency(response)
	end
	settings.devtracker_page_title = 'Sector '+highLevelCode+' Programmes Page'
	#####
	dac2Code = sanitize_input(params[:high_level_sector_code],"p")
	high_level_sector_list = ''
	fileName = 'sector_dac2_search_'+dac2Code
	if (!canLoadFromCache(fileName))
		prepSectorCodeFilter = ''
		sectorHierarchy = JSON.parse(File.read('data/sectorHierarchies.json')).select{|s| s['High Level Code (L1)'].to_i == dac2Code.to_i}
		sectorHierarchy.each_with_index do |elem, index|
			if index == sectorHierarchy.length-1
				prepSectorCodeFilter = prepSectorCodeFilter + elem['Code (L3)'].to_s
			else
				prepSectorCodeFilter = prepSectorCodeFilter + elem['Code (L3)'].to_s + ' OR '
			end
		end
		newApiCall = settings.oipa_api_url + "activity?q=participating_org_ref:GB-GOV-* AND reporting_org_ref:(#{settings.goverment_department_ids.gsub(","," OR ")}) AND sector_code:("+prepSectorCodeFilter+") AND budget_period_start_iso_date:[#{settings.current_first_day_of_financial_year}T00:00:00Z TO *] AND budget_period_end_iso_date:[* TO #{settings.current_last_day_of_financial_year}T00:00:00Z]&fl=iati_identifier,budget_value,recipient_country_code,recipient_region_code,budget_period_start_iso_date,budget_period_end_iso_date,sector_code,sector_percentage,&rows=50000"
		pulledData = RestClient.get newApiCall
		#storeCacheData(sector_parent_data_list( settings.oipa_api_url, "category", "Category (L2)", "Category Name", "High Level Code (L1)", "High Level Sector Description", dac2Code, "category"), fileName)
		storeCacheData(sector_parent_data_listv2(pulledData, sectorHierarchy), fileName)
		high_level_sector_list = getCacheData(fileName)
	else
		high_level_sector_list = getCacheData(fileName)
	end
	#####
  	#erb :'search/solrSectors',
	erb :'search/solrTemplate',
	:layout => :'layouts/layout',
	:locals => 
	{
		oipa_api_url: settings.oipa_api_url,
		query: query,
		filters: filters,
		response: response,
		solrConfig: Oj.load(File.read('data/solr-config.json')),
		activityStatus: Oj.load(File.read('data/activity_status.json')),
		level: 1,
		searchType: 'S',
		breadcrumbURL: '/sector',
		breadcrumbText: 'Aid by Department',
		sector_list: high_level_sector_list,#sector_parent_data_listv2( settings.oipa_api_url, "category", "Category (L2)", "Category Name", "High Level Code (L1)", "High Level Sector Description", sectorData['highLevelCode'], "category"),
		sectorData: sectorData
	}
end

# List of all the 3 DAC projects 
get '/sector/:high_level_sector_code/categories/:category_code/projects/?' do
	highLevelCode = sanitize_input(params[:high_level_sector_code],"p")
	categoryCode = sanitize_input(params[:category_code],"p")
	sectorCode = ''
	#Segment
	sectorData = {}
	sectorData['highLevelCode'] = highLevelCode
	sectorData['sectorCode'] = ""
	sectorData['categoryCode'] = categoryCode
	sectorData['sectorName'] = ""
	#Segment
	sectorJsonData = JSON.parse(File.read('data/sectorHierarchies.json'))#map_sector_data()
	sectorJsonData = sectorJsonData.select {|sector| sector['Category (L2)'] == categoryCode.to_i}
	sectorJsonData.each do |sdata|
		sectorCode.concat(sdata['Code (L3)'].to_s + " OR ")
		sectorData['sectorCode'].concat(sdata['Code (L3)'].to_s + ",")
	end
	query = "(" + sectorCode[0, sectorCode.length - 3] + ")"
	filters = prepareFilters(query.to_s, 'S')
	response = solrResponse(query, 'AND activity_status_code:(2)', 'S', 0, '', '')
	if(response['numFound'].to_i > 0)
		response = addTotalBudgetWithCurrency(response)
	end
	##
	dac2Code = sanitize_input(params[:high_level_sector_code],"p")
	catCode = sanitize_input(params[:category_code],"p")
	high_level_sector_list = ''
	fileName = 'sector_dac2_search_'+dac2Code+'_'+catCode
	if (!canLoadFromCache(fileName))
		prepSectorCodeFilter = ''
		sectorHierarchy = JSON.parse(File.read('data/sectorHierarchies.json')).select{|s| s['Category (L2)'].to_i == catCode.to_i}
		sectorHierarchy.each_with_index do |elem, index|
			if index == sectorHierarchy.length-1
				prepSectorCodeFilter = prepSectorCodeFilter + elem['Code (L3)'].to_s
			else
				prepSectorCodeFilter = prepSectorCodeFilter + elem['Code (L3)'].to_s + ' OR '
			end
		end
		newApiCall = settings.oipa_api_url + "activity?q=participating_org_ref:GB-GOV-* AND reporting_org_ref:(#{settings.goverment_department_ids.gsub(","," OR ")}) AND sector_code:("+prepSectorCodeFilter+") AND budget_period_start_iso_date:[#{settings.current_first_day_of_financial_year}T00:00:00Z TO *] AND budget_period_end_iso_date:[* TO #{settings.current_last_day_of_financial_year}T00:00:00Z]&fl=iati_identifier,budget_value,recipient_country_code,recipient_region_code,budget_period_start_iso_date,budget_period_end_iso_date,sector_code,sector_percentage,&rows=50000"
		pulledData = RestClient.get newApiCall
		#storeCacheData(sector_parent_data_list( settings.oipa_api_url, "category", "Category (L2)", "Category Name", "High Level Code (L1)", "High Level Sector Description", dac2Code, "category"), fileName)
		storeCacheData(sector_parent_data_dac5(pulledData, sectorHierarchy), fileName)
		#storeCacheData(sector_parent_data_list(settings.oipa_api_url, "sector", "Code (L3)", "Name", "Category (L2)", "Category Name", sanitize_input(params[:high_level_sector_code],"p"), sanitize_input(params[:category_code],"p")), fileName)
		high_level_sector_list = getCacheData(fileName)
	else
		high_level_sector_list = getCacheData(fileName)
	end
	##
	settings.devtracker_page_title = 'Sector Category '+sanitize_input(params[:category_code],"p")+' Programmes Page'
  	#erb :'search/solrSectors',
	erb :'search/solrTemplate',
	:layout => :'layouts/layout',
	:locals => 
	{
		oipa_api_url: settings.oipa_api_url,
		query: query,
		filters: filters,
		response: response,
		solrConfig: Oj.load(File.read('data/solr-config.json')),
		activityStatus: Oj.load(File.read('data/activity_status.json')),
		level: 2,
		searchType: 'S',
		breadcrumbURL: '/sector',
		breadcrumbText: 'Aid by Department',
		sector_list: high_level_sector_list,#sector_parent_data_list(settings.oipa_api_url, "sector", "Code (L3)", "Name", "Category (L2)", "Category Name", sectorData['highLevelCode'], sectorData['categoryCode']),
		sectorData: sectorData
	}
end

# Sector All Projects Page (e.g. Five Digit DAC Sector)
get '/sector/:high_level_sector_code/categories/:category_code/projects/:sector_code/?' do
	highLevelCode = sanitize_input(params[:high_level_sector_code],"p")
	categoryCode = sanitize_input(params[:category_code],"p")
	dac5Code = sanitize_input(params[:sector_code],"p")
	#Segment
	sectorData = {}
	sectorData['highLevelCode'] = highLevelCode
	sectorData['categoryCode'] = categoryCode
	sectorData['sectorCode'] = dac5Code
	#Segment
	# Get the five digit DAC sector project data from the API
	sectorJsonData = JSON.parse(File.read('data/sectorHierarchies.json'))#map_sector_data()
	sectorJsonData = sectorJsonData.select {|sector| sector['Code (L3)'] == dac5Code.to_i}.first
	dac5SectorName = sectorJsonData['Name']
	sectorData['sectorName'] = sectorJsonData['Name']
	query = "(" + sectorJsonData['Code (L3)'].to_s + ")"
	filters = prepareFilters(query.to_s, 'S')
	response = solrResponse(query, 'AND activity_status_code:(2)', 'S', 0, '', '')
	if(response['numFound'].to_i > 0)
		response = addTotalBudgetWithCurrency(response)
	end
	##
	dac2Code = sanitize_input(params[:high_level_sector_code],"p")
	catCode = sanitize_input(params[:category_code],"p")
	high_level_sector_list = ''
	fileName = 'sector_dac2_search_'+dac2Code+'_'+catCode+'_'+dac5Code
	if (!canLoadFromCache(fileName))
		prepSectorCodeFilter = ''
		sectorHierarchy = JSON.parse(File.read('data/sectorHierarchies.json')).select{|s| s['Category (L2)'].to_i == catCode.to_i}
		sectorHierarchy.each_with_index do |elem, index|
			if index == sectorHierarchy.length-1
				prepSectorCodeFilter = prepSectorCodeFilter + elem['Code (L3)'].to_s
			else
				prepSectorCodeFilter = prepSectorCodeFilter + elem['Code (L3)'].to_s + ' OR '
			end
		end
		newApiCall = settings.oipa_api_url + "activity?q=participating_org_ref:GB-GOV-* AND reporting_org_ref:(#{settings.goverment_department_ids.gsub(","," OR ")}) AND sector_code:("+prepSectorCodeFilter+") AND budget_period_start_iso_date:[#{settings.current_first_day_of_financial_year}T00:00:00Z TO *] AND budget_period_end_iso_date:[* TO #{settings.current_last_day_of_financial_year}T00:00:00Z]&fl=iati_identifier,budget_value,recipient_country_code,recipient_region_code,budget_period_start_iso_date,budget_period_end_iso_date,sector_code,sector_percentage,&rows=50000"
		pulledData = RestClient.get newApiCall
		#storeCacheData(sector_parent_data_list( settings.oipa_api_url, "category", "Category (L2)", "Category Name", "High Level Code (L1)", "High Level Sector Description", dac2Code, "category"), fileName)
		storeCacheData(sector_parent_data_dac5(pulledData, sectorHierarchy), fileName)
		#storeCacheData(sector_parent_data_list(settings.oipa_api_url, "sector", "Code (L3)", "Name", "Category (L2)", "Category Name", sanitize_input(params[:high_level_sector_code],"p"), sanitize_input(params[:category_code],"p")), fileName)
		high_level_sector_list = getCacheData(fileName)
	else
		high_level_sector_list = getCacheData(fileName)
	end
	##
	#getSectorProjects = get_sector_projects(sectorData['sectorCode'])
  	settings.devtracker_page_title = 'Sector ' + dac5Code + ' Programmes Page'
  	#erb :'search/solrSectors',
	erb :'search/solrTemplate',
	:layout => :'layouts/layout',
	:locals => 
	{
		oipa_api_url: settings.oipa_api_url,
		query: query,
		filters: filters,
		response: response,
		solrConfig: Oj.load(File.read('data/solr-config.json')),
		activityStatus: Oj.load(File.read('data/activity_status.json')),
		level: 3,
		searchType: 'S',
		breadcrumbURL: '/sector',
		breadcrumbText: 'Aid by Sector',
		sector_list: high_level_sector_list,#sector_parent_data_list(settings.oipa_api_url, "sector", "Code (L3)", "Name", "Category (L2)", "Category Name", sectorData['highLevelCode'], sectorData['categoryCode']),
 		sectorData: sectorData
	}	
end

#####################################################################
#  CURRENCY HANDLER
#####################################################################


get '/currency/?' do
  	settings.devtracker_page_title = 'Currency API'
  	amount = sanitize_input(params['amount'],"a")
  	currency = sanitize_input(params['currency'],"a")
  	returnCurrency = Money.new(amount.to_f*100,currency).format(:no_cents_if_whole => true,:sign_before_symbol => false)
	json :output => returnCurrency
end


#####################################################################
#  CSV HANDLER
#####################################################################


get '/downloadCSV/:proj_id/:transaction_type?' do
	projID = sanitize_input(params[:proj_id],"newId")
	transactionType = sanitize_input(params[:transaction_type],"p")
	#transactionsForCSV = convert_transactions_for_csv(projID,transactionType)
	#tempTransactions = transaction_data_hash_table_for_csv(transactionsForCSV,transactionType,projID)
	if transactionType.to_i == 0
		data = get_project_yearwise_budgetv2(projID)
	else
		data = get_transactionsv2(projID,transactionType)
	end
	tempTransactions = transaction_data_hash_table_for_csvv2(data,transactionType,projID)
	#tempTitle = transactionsForCSV.first
	transactionTypes = Oj.load(File.read('data/custom-codes/TransactionType.json'))['data']
	t = transactionTypes.select{|s| s['code'].to_i == transactionType.to_i}.first
	content_type 'text/csv'
	if transactionType != '0'
		attachment "Export-" +t['name']+ "s.csv"
	else
		attachment "Export-Budgets.csv"
	end
	tempTransactions
end

get '/downloadLocationDataCSV/:proj_id?' do
	projID = sanitize_input(params[:proj_id],"newId")
	locationData = location_data_for_csv(projID)
	content_type 'text/csv'
	attachment "Export-locations-"+projID+".csv"
	locationData
end

get '/downloadLocationDataCountriesCSV/:countryCode?' do
	countryCode = sanitize_input(params[:countryCode],"p")
	locationData = location_data_for_countries_csv(countryCode)
	content_type 'text/csv'
	attachment "Export-locations-"+countryCode+".csv"
	locationData
end

get '/clear-cache' do
	FileUtils.rm_rf(Dir['data/cache/*'])
	json :output => 'cache cleared'
end

#####################################################################
#  TEST PAGES
#####################################################################

get '/test01' do  #homepage
	#read static data from JSON files for the front page
	liveURL = 'https://devtracker-entry.oipa.nl/api/activities/?hierarchy=1&format=json&reporting_organisation_identifier=GB-GOV-15,GB-GOV-9,GB-GOV-6,GB-GOV-2,GB-GOV-1,GB-1,GB-GOV-3,GB-GOV-13,GB-GOV-7,GB-GOV-50,GB-GOV-52,GB-6,GB-10,GB-GOV-10,GB-9,GB-GOV-8,GB-GOV-5,GB-GOV-12,GB-COH-RC000346,GB-COH-03877777,GB-GOV-24&page_size=149&fields=activity_plus_child_aggregation,aggregations&activity_status=1,2,3,4,5&ordering=-activity_plus_child_budget_value&recipient_country=BD'
	solrURL = 'https://fcdo.iati.cloud//search/activity/?q=hierarchy:1%20AND%20participating_org_ref:GB-GOV-*%20AND%20recipient_country_code:(BD)%20AND%20reporting_org_ref:(GB-GOV-15%20OR%20GB-GOV-9%20OR%20GB-GOV-6%20OR%20GB-GOV-2%20OR%20GB-GOV-1%20OR%20GB-1%20OR%20GB-GOV-3%20OR%20GB-GOV-13%20OR%20GB-GOV-7%20OR%20GB-GOV-50%20OR%20GB-GOV-52%20OR%20GB-6%20OR%20GB-10%20OR%20GB-GOV-10%20OR%20GB-9%20OR%20GB-GOV-8%20OR%20GB-GOV-5%20OR%20GB-GOV-12%20OR%20GB-COH-RC000346%20OR%20GB-COH-03877777)AND%20activity_status_code:(1%20OR%202%20OR%203%20OR%204%20OR%205)&rows=149&fl=iati_identifier,%20child_aggregation_*,%20activity_plus_child_aggregation*,%20activity_aggregation_*&start=0'
  	settings.devtracker_page_title = 'Test data'
  	# Example of setting up a cookie from server end
  	# response.set_cookie('my_cookie', 'value_of_cookie')
	#liveData = Oj.load(File.read('data/data-comparison/live-data.json'))
	liveData = Oj.load(RestClient.get liveURL) 
	#solrData = Oj.load(File.read('data/data-comparison/solr-data.json'))
	solrData = Oj.load(RestClient.get solrURL)
	activities = {}
	liveData['results'].each do |val|
		activities[val['iati_identifier']] = {}
		activities[val['iati_identifier']]['livebudget_value'] = val['activity_plus_child_aggregation']['activity_children']['budget_value']
		activities[val['iati_identifier']]['livebudget_currency'] = val['activity_plus_child_aggregation']['activity_children']['budget_currency']
		activities[val['iati_identifier']]['livedisbursement_currency'] = val['activity_plus_child_aggregation']['activity_children']['disbursement_currency']
		activities[val['iati_identifier']]['livecommitment_currency'] = val['activity_plus_child_aggregation']['activity_children']['commitment_currency']
		activities[val['iati_identifier']]['liveexpenditure_currency'] = val['activity_plus_child_aggregation']['activity_children']['expenditure_currency']
	end
	solrData['response']['docs'].each do |val|
		if activities.has_key?(val['iati_identifier'])
			activities[val['iati_identifier']]['activity_plus_child_aggregation_budget_value'] = val['activity_plus_child_aggregation_budget_value']
			activities[val['iati_identifier']]['activity_plus_child_aggregation_budget_currency'] = val['activity_plus_child_aggregation_budget_currency']
			activities[val['iati_identifier']]['activity_plus_child_aggregation_disbursement_currency'] = val['activity_plus_child_aggregation_disbursement_currency']
			activities[val['iati_identifier']]['activity_plus_child_aggregation_commitment_currency'] = val['activity_plus_child_aggregation_commitment_currency']
			activities[val['iati_identifier']]['activity_plus_child_aggregation_expenditure_currency'] = val['activity_plus_child_aggregation_expenditure_currency']
		else
			activities[val['iati_identifier']] = {}
			activities[val['iati_identifier']]['livebudget_value'] = val['iati_identifier']
			activities[val['iati_identifier']]['livebudget_currency'] = 'N/A'
			activities[val['iati_identifier']]['livedisbursement_currency'] = 'N/A'
			activities[val['iati_identifier']]['livecommitment_currency'] = 'N/A'
			activities[val['iati_identifier']]['liveexpenditure_currency'] = 'N/A'
			activities[val['iati_identifier']]['activity_plus_child_aggregation_budget_value'] = val['activity_plus_child_aggregation_budget_value']
			activities[val['iati_identifier']]['activity_plus_child_aggregation_budget_currency'] = val['activity_plus_child_aggregation_budget_currency']
			activities[val['iati_identifier']]['activity_plus_child_aggregation_disbursement_currency'] = val['activity_plus_child_aggregation_disbursement_currency']
			activities[val['iati_identifier']]['activity_plus_child_aggregation_commitment_currency'] = val['activity_plus_child_aggregation_commitment_currency']
			activities[val['iati_identifier']]['activity_plus_child_aggregation_expenditure_currency'] = val['activity_plus_child_aggregation_expenditure_currency']
		end
	end
	erb :'tests/index',
 		:layout => :'layouts/landing', 
 		:locals => {
 			oipa_api_url: settings.oipa_api_url,
			 activities: activities
 		}
end

#####################################################################
#  STATIC PAGES
#####################################################################


get '/department' do
  	settings.devtracker_page_title = 'Aid by Department Page'
  	odas = Oj.load(File.read('data/odas.json'))
  	totalOdaValue = 0
  	odas.each do |oda|
  		if oda[1][0]["value"] >= 0
  			totalOdaValue = totalOdaValue + oda[1][0]["value"]
  		end
  	end
	erb :'department/department', :layout => :'layouts/layout', :locals => {oipa_api_url: settings.oipa_api_url, odas: odas, totalOdaValue: totalOdaValue}
end

get '/about/?' do
  	settings.devtracker_page_title = 'About DevTracker Page'
	erb :'about/about', :layout => :'layouts/layout', :locals => {oipa_api_url: settings.oipa_api_url}
end

get '/custom-codes/?' do
	# Process policy priorities
	policyPriorities = Oj.load(File.read('data/custom-codes/policy-priorities.json'))
	settings.devtracker_page_title = 'Custom Codes & Vocabularies'
	erb :'custom-codes/custom-codes', :layout => :'layouts/layout', :locals => 
	{
		oipa_api_url: settings.oipa_api_url,
		policyPriorities: policyPriorities
	}
end 

get '/accessibility-statement/?' do
  	settings.devtracker_page_title = 'Accessibility Statement Page'
	erb :'accessibility/accessibility-statement', :layout => :'layouts/layout', :locals => {oipa_api_url: settings.oipa_api_url}
end

get '/cookies/?' do
  	settings.devtracker_page_title = 'Cookies Page'
	erb :'cookies/index', :layout => :'layouts/layout', :locals => {oipa_api_url: settings.oipa_api_url}
end

get '/privacy-policy/?' do
	settings.devtracker_page_title = 'Privacy Policy'
  erb :'privacy-policy/index', :layout => :'layouts/layout', :locals => {oipa_api_url: settings.oipa_api_url}
end

get '/faq/?' do
  	settings.devtracker_page_title = 'FAQ: What does this mean?'
	erb :'faq/faq', :layout => :'layouts/layout', :locals => {oipa_api_url: settings.oipa_api_url }
end

get '/whats-new/?' do
  	settings.devtracker_page_title = "What's New Page"
	erb :'about/whats-new', :layout => :'layouts/layout', :locals => {oipa_api_url: settings.oipa_api_url}
end

get '/test-cache?' do
	randomNumber = rand(2)
	if (randomNumber.to_i.even?)
		json :output => xx['xx']
	else
		json :output => randomNumber
	end
end

#####################################################################
#  RSS FEED
#####################################################################

# RSS by country
get '/rss/country/:country_code/?' do |n|
	#remove any trailing .rss and sanitize
	n.slice!(".rss")
	n = sanitize_input(n,"p")
	
	#get country name from country code
	countryName = get_country_code_name(n)

  	rss = RSS::Maker.make("atom") do |maker|

	    projects = ''
		projects = get_country_all_projects_rss(n)

	    maker.channel.author = "Department for International Development"
	    maker.channel.updated = Time.now.to_s
	    maker.channel.about = "A breakdown of all the Programmes that have changed for #{countryName[:name]} on DevTracker in reverse chronological order"
	    maker.channel.title = "FCDO Programmes feed for #{countryName[:name]}"
	    maker.channel.link = "https://devtracker.fcdo.gov.uk/countries/#{n}/projects/"

	    projects.each do |project|
	      maker.items.new_item do |item|
	        #convert lastUpdatedDatetime to UTC
	        lastUpdatedDateTimeUtc = Time.strptime(project['last_updated_datetime'], '%Y-%m-%dT%H:%M:%S').utc	        
	        item.link = "https://devtracker.fcdo.gov.uk/projects/" + ERB::Util.url_encode(project['iati_identifier']).to_s + "/summary/"
	        item.title = project['title']['narratives'][0]['text']
	        item.description = project['descriptions'][0]['narratives'][0]['text'] + " [Last updated: " + lastUpdatedDateTimeUtc.strftime('%Y-%m-%d %H:%M:%S %Z') + "]"
	        item.updated = lastUpdatedDateTimeUtc
	      end
	    end
  	end

  	content_type 'text/xml'
  	settings.devtracker_page_title = "RSS Feed for " + countryName[:name] + " Page"
  	erb :'rss/index', :layout => false, :locals => {:rss => rss}

end 


#####################################################################
#  ERROR PAGES
#####################################################################

# 404 Error!
not_found do
  status 404
  settings.devtracker_page_title = "Error 404(Page not found!)"
  erb :'404', :layout => :'layouts/layout', :locals => {oipa_api_url: settings.oipa_api_url}
end

error 404 do
  status 404
  settings.devtracker_page_title = "Error 404(Page not found!)"
  erb :'404', :layout => :'layouts/layout', :locals => {oipa_api_url: settings.oipa_api_url}
end

error 500 do
  status 500
  settings.devtracker_page_title = "Error 500 Page"
  erb :'500', :layout => :'layouts/layout', :locals => {oipa_api_url: settings.oipa_api_url}
end

