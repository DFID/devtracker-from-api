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
# set :oipa_api_url, 'https://devtracker.fcdo.gov.uk/api/'
# set :oipa_api_url, 'https://devtracker-entry.oipa.nl/api/'
# set :oipa_api_url, 'https://fcdo.iati.cloud/api/'
set :oipa_api_url_solr, 'https://fcdo.iati.cloud/search/'
# set :oipa_api_url, 'https://devtracker-staging.oipa.nl/api/'
# set :bind, '0.0.0.0' # Allows for vagrant pass-through whilst debugging

# Server Machine: set global settings to use varnish cache
set :oipa_api_url, 'http://127.0.0.1:6081/api/'

#set :oipa_api_url, 'https://iatidatastore.iatistandard.org/api/'

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
set :google_recaptcha_publicKey, ENV["GOOGLE_PUBLIC_KEY"]
set :google_recaptcha_privateKey, ENV["GOOGLE_PRIVATE_KEY"]

set :raise_errors, true
set :show_exceptions, true
set :log_api_calls, false

set :devtracker_page_title, ''
#####################################################################
#  HOME PAGE
#####################################################################

get '/' do  #homepage
	#read static data from JSON files for the front page
	top5results = JSON.parse(File.read('data/top5results.json'))
  	top5countries = get_top_5_countries()
  	odas = Oj.load(File.read('data/odas.json'))
  	odas = odas.first(10)
  	settings.devtracker_page_title = ''
  	# Example of setting up a cookie from server end
  	# response.set_cookie('my_cookie', 'value_of_cookie')
	erb :index,
 		:layout => :'layouts/landing', 
 		:locals => {
 			top_5_countries: top5countries, 
 			what_we_do: high_level_sector_list( get_5_dac_sector_data(), "top_five_sectors", "High Level Code (L1)", "High Level Sector Description"), 
 			what_we_achieve: top5results,
 			odas: odas,
 			oipa_api_url: settings.oipa_api_url
 		}
end

#####################################################################
#  COUNTRY PAGES
#####################################################################

# Country summary page
get '/countries/:country_code/?' do |n|
	n = sanitize_input(n,"p").upcase
	country = ''
	results = ''
	countryYearWiseBudgets = ''
	countrySectorGraphData = ''
	tempActivityCount = Oj.load(RestClient.get  api_simple_log(settings.oipa_api_url + "activities/?format=json&recipient_country="+n+"&reporting_org_identifier=#{settings.goverment_department_ids}&page_size=1"))
	if n == 'UA'
		tempActivityCount['count'] = 0
	end
	Benchmark.bm(7) do |x|
	 	x.report("Loading Time: ") {
	 		country = get_country_details(n)
	 		results = get_country_results(n)
			#oipa v3.1
			countrySectorGraphData = get_country_sector_graph_data(RestClient.get  api_simple_log(settings.oipa_api_url + "budgets/aggregations/?reporting_organisation_identifier=#{settings.goverment_department_ids}&order_by=-value&group_by=sector&aggregations=value&format=json&recipient_country=#{n}"))
	 	}
	end
	#----- Following project count code needs to be deprecated before merging with main solr branch work ----------------------
	country[:totalProjects] = Oj.load(RestClient.get  api_simple_log(settings.oipa_api_url_solr + 'activity?q=participating_org_ref:GB-*'+add_exclusions_to_solr2()+' AND reporting_org_ref:('+settings.goverment_department_ids.gsub(","," OR ")+') AND recipient_country_code:('+n+') AND hierarchy:1 AND activity_status_code:2&fl=iati_identifier&rows=1'))['response']['numFound']
	#countryYearWiseBudgets= get_country_region_yearwise_budget_graph_data(RestClient.get  api_simple_log(settings.oipa_api_url + "budgets/aggregations/?format=json&reporting_organisation_identifier=#{settings.goverment_department_ids}&group_by=budget_period_start_quarter&aggregations=value&recipient_country=#{n}&order_by=budget_period_start_year,budget_period_start_quarter"))
	implementingOrgList = getCountryLevelImplOrgs(n,tempActivityCount['count'])
	ogds = Oj.load(File.read('data/OGDs.json'))
	topSixResults = pick_top_six_results(n)
	#Geo Location data of country
	geoJsonData = getCountryBounds(n)
	# Get a list of map markers
	mapMarkers = getCountryMapMarkers(n)
	puts settings.oipa_api_url + "budgets/aggregations/?format=json&reporting_organisation_identifier=#{settings.goverment_department_ids}&group_by=recipient_country,reporting_organisation,budget_period_start_quarter&aggregations=value&recipient_country=#{n}&order_by=budget_period_start_year,budget_period_start_quarter"
	countryBudgetBarGraphDataSplit2 = budgetBarGraphDataD(settings.oipa_api_url + "budgets/aggregations/?format=json&reporting_organisation_identifier=#{settings.goverment_department_ids}&group_by=recipient_country,reporting_organisation,budget_period_start_quarter&aggregations=value&recipient_country=#{n}&order_by=budget_period_start_year,budget_period_start_quarter", 'i')
	#puts countryBudgetBarGraphDataD
  	settings.devtracker_page_title = 'Country ' + country[:name] + ' Summary Page'
	erb :'countries/country', 
		:layout => :'layouts/layout',
		:locals => {
 			country: country,
 			#countryYearWiseBudgets: countryYearWiseBudgets,
 			countrySectorGraphData: countrySectorGraphData,
 			results: results,
 			topSixResults: topSixResults,
 			oipa_api_url: settings.oipa_api_url,
 			activityCount: tempActivityCount['count'],
 			implementingOrgList: implementingOrgList,
 			countryGeoJsonData: geoJsonData,
			mapMarkers: mapMarkers,
			chartDataRepOrgsSplit2: countryBudgetBarGraphDataSplit2[0],
			chartDataFinYearsSplit2: countryBudgetBarGraphDataSplit2[1],
			chartDataColumnDataSplit2: countryBudgetBarGraphDataSplit2[2],
 		}
end

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
  	settings.devtracker_page_title = 'Country ' + country[:name] + ' Programmes Page'
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
    region = get_region_details(n)
	#oipa v3.1
	#regionYearWiseBudgets = budgetBarGraphData("budgets/aggregations/?format=json&reporting_organisation_identifier=#{settings.goverment_department_ids}&group_by=reporting_organisation,budget_period_start_quarter&aggregations=value&recipient_region=#{n}&order_by=budget_period_start_year,budget_period_start_quarter")
	regionYearWiseBudgets= get_country_region_yearwise_budget_graph_data(RestClient.get  api_simple_log(settings.oipa_api_url + "budgets/aggregations/?format=json&reporting_organisation_identifier=#{settings.goverment_department_ids}&group_by=budget_period_start_quarter&aggregations=value&recipient_region=#{n}&order_by=budget_period_start_year,budget_period_start_quarter"))
	regionSectorGraphData = get_country_sector_graph_data(RestClient.get  api_simple_log(settings.oipa_api_url + "budgets/aggregations/?reporting_organisation_identifier=#{settings.goverment_department_ids}&order_by=-value&group_by=sector&aggregations=value&format=json&recipient_region=#{n}"))
  	settings.devtracker_page_title = 'Region '+region[:name]+' Summary Page'
	erb :'regions/region', 
		:layout => :'layouts/layout',
		:locals => {
			oipa_api_url: settings.oipa_api_url,
 			region: region,
 			regionYearWiseBudgets: regionYearWiseBudgets,
 			regionSectorGraphData: regionSectorGraphData,
 			mapMarkers: getRegionMapMarkers(region[:code]),
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
  	project = get_h1_project_details(n)
  	participatingOrgList = get_participating_organisations(project)
  	#get the country/region data from the API
  	countryOrRegion = get_country_or_region(n)
  	#get total project budget and spend Data
  	#projectBudget = get_project_budget(n)

  	#get project sectorwise graph  data
  	projectSectorGraphData = get_project_sector_graph_data(n)
	# get the funding projects Count from the API
  	#fundingProjectsCount = get_funding_project_count(n)
	# get the funded projects Count from the API
	#fundedProjectsCount = 0
	# getProjectIdentifierList(n)['projectIdentifierListArray'].each do |id|
	# 	begin
	# 		fundedProjectsCount = fundedProjectsCount + JSON.parse(RestClient.get  api_simple_log(settings.oipa_api_url + "activities/?format=json&transaction_provider_activity=#{id}&page_size=1&fields=id&ordering=title"))['count'].to_i
	# 	rescue
	# 		puts id
	# 	end
	# end
	#Policy markers
	begin
		getPolicyMarkers = get_policy_markers(n)
		puts 'policy markers grabbed'
	rescue
		getPolicyMarkers = Array.new
	end
	policyMarkerCount = 0
	getPolicyMarkers.each do |marker|
		if(marker['significance']['code'].to_i != 0)
			policyMarkerCount += 1
		end
	end
  	settings.devtracker_page_title = 'Programme '+project['iati_identifier']
	erb :'projects/summary', 
		:layout => :'layouts/layout',
		 :locals => {
			projectId: n,
		 	oipa_api_url: settings.oipa_api_url,
 			project: project,
 			countryOrRegion: countryOrRegion,	 					 			
 			#fundedProjectsCount: fundedProjectsCount,
 			#fundingProjectsCount: fundingProjectsCount,
 			#projectBudget: projectBudget,
 			projectSectorGraphData: projectSectorGraphData,
 			participatingOrgList: participatingOrgList,
 			policyMarkers: getPolicyMarkers,
 			policyMarkersCount: policyMarkerCount,
 			mapMarkers: getProjectMapMarkers(n)
 		}
end

# Project documents page
get '/projects/*/documents/?' do
	#n = sanitize_input(n,"p")
	n = ERB::Util.url_encode (params['splat'][0]).to_s
	check_if_project_exists(n)
	# get the project data from the API
	project = get_h1_project_details(n)

  	#get the country/region data from the API
  	#countryOrRegion = get_country_or_region(n)

  	# get the funding projects Count from the API
  	#fundingProjectsCount = get_funding_project_count(n)

	# get the funded projects Count from the API
	# fundedProjectsCount = 0
	# getProjectIdentifierList(n)['projectIdentifierListArray'].each do |id|
	# 	begin
	# 		fundedProjectsCount = fundedProjectsCount + JSON.parse(RestClient.get  api_simple_log(settings.oipa_api_url + "activities/?format=json&transaction_provider_activity=#{id}&page_size=1&fields=id&ordering=title"))['count'].to_i
	# 	rescue
	# 		puts id
	# 	end
	# end
  	
  	settings.devtracker_page_title = 'Programme '+project['iati_identifier']+' Documents'
	erb :'projects/documents', 
		:layout => :'layouts/layout',
		:locals => {
			oipa_api_url: settings.oipa_api_url,
 			project: project,
 			# countryOrRegion: countryOrRegion,
 			# fundedProjectsCount: fundedProjectsCount,
 			# fundingProjectsCount: fundingProjectsCount 
 		}
end

#Project transactions page
get '/projects/*/transactions/?' do
	n = ERB::Util.url_encode (params['splat'][0]).to_s
	check_if_project_exists(n)
	#n = sanitize_input(n,"p")
	# get the project data from the API
	project = get_h1_project_details(n)
	#componentData = get_project_component_data(project)
		
	# get the transactions from the API
  	# incomingFunds = get_transaction_details(n,"1")

  	# # get the incomingFund transactions from the API
  	# commitments = get_transaction_details(n,"2")

  	# # get the disbursement transactions from the API
  	# disbursements = get_transaction_details(n,"3")

  	# # get the expenditure transactions from the API
  	# expenditures = get_transaction_details(n,"4")

  	# # get the Interest Repayment transactions from the API
  	# interestRepayment = get_transaction_details(n,"5")

  	# # get the Loan Repayment transactions from the API
  	# loanRepayment = get_transaction_details(n,"6")

  	# # get the Purchase of Equity transactions from the API
  	# purchaseEquity = get_transaction_details(n,"8")

  	# get yearly budget for H1 Activity from the API
	#projectYearWiseBudgets= get_project_yearwise_budget(n)

	# get the funded projects Count from the API
		
  	settings.devtracker_page_title = 'Programme '+project['iati_identifier']+' Transactions'
	erb :'projects/transactions', 
		:layout => :'layouts/layout',
		:locals => {
			oipa_api_url: settings.oipa_api_url,
			project: project,
 			# incomingFunds: incomingFunds,
 			# commitments: commitments,
 			# disbursements: disbursements,
 			# expenditures: expenditures,
 			# interestRepayments: interestRepayment,
 			# loanRepayments: loanRepayment,
 			# purchaseEquities: purchaseEquity,
 		}
end

#Project transactions page
get '/projects/*/components/?' do
	n = ERB::Util.url_encode (params['splat'][0]).to_s
	check_if_project_exists(n)
	#n = sanitize_input(n,"p")
	# get the project data from the API
	project = get_h1_project_details(n)
	#componentData = get_project_component_data(project)

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

post '/transaction-details-page' do
	project = sanitize_input(params['data']['projectID'].to_s,"newId")
	transactionType = sanitize_input(params['data']['transactionType'].to_s, "a")
	resultCount = 20
	nextPage = sanitize_input(params['data']['nextPage'].to_s, "a")
	json :output => get_transaction_details_page(project,transactionType, nextPage, resultCount)
end

post '/transaction-total' do
	project = sanitize_input(params['data']['project'].to_s,"newId")
	transactionType = sanitize_input(params['data']['transactionType'].to_s, "a")
	currency = sanitize_input(params['data']['currency'].to_s, "newId")
	json :output => get_transaction_total(project,transactionType, currency)
end

get '/component-list/*?' do
	n = ERB::Util.url_encode (params['splat'][0]).to_s
	oipa = RestClient.get  api_simple_log(settings.oipa_api_url + "activities/#{n}/?format=json&fields=iati_identifier,related_activity")
    project = JSON.parse(oipa)
	tempData = []
	project['related_activity'].each do |item|
		if(item['type']['code'].to_i == 2)
			tempData.push(item['ref'])
		end
	end
	json :output => tempData
end

# Get yearly budget for H1 Activity from the API
get '/project-yearwise-budget/*?' do
	n = ERB::Util.url_encode (params['splat'][0]).to_s
	projectYearWiseBudgets= get_project_yearwise_budget(n)
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
	project = get_h1_project_details(n)
	projectYearWiseBudgets= get_project_yearwise_budget(n)
	totalProjectBudget=get_sum_budget(projectYearWiseBudgets).to_f
	begin
		data = Money.new(totalProjectBudget.round(0)*100, if project['activity_plus_child_aggregation']['activity_children']['budget_currency'].nil? then project['default_currency']['code'] else project['activity_plus_child_aggregation']['activity_children']['budget_currency'] end).format(:no_cents_if_whole => true,:sign_before_symbol => false)
	rescue
		data = "£#{totalProjectBudget}"
	end
	json :output=> data
end

get '/project-details/*?' do
	n = ERB::Util.url_encode (params['splat'][0]).to_s
	oipa = RestClient.get api_simple_log(settings.oipa_api_url + "activities/#{n}/?format=json&fields=iati_identifier,title,description,activity_date")
	oipa = JSON.parse(oipa)
	tempData = {}
	tempData['iati_identifier'] = oipa['iati_identifier']
	tempData['title'] = begin oipa['title']['narrative'][0]['text'] rescue 'N/A' end
	tempData['description'] = begin oipa['description'][0]['narrative'][0]['text'] rescue 'N/A' end
	tempData['activity_date'] = {}
	tempData['activity_dates'] = bestActivityDate(oipa['activity_date'])
	json :output=> tempData
end

get '/country-or-region/*?' do
	n = ERB::Util.url_encode (params['splat'][0]).to_s
	json :output=> get_country_or_region(n)
end

# Get the funding projects Count from the API
get '/get-funding-projects/*?' do
	n = ERB::Util.url_encode (params['splat'][0]).to_s
	json :output=> get_funding_project_count(n)
end

# Get funded project counts
get '/get-funded-projects/*?' do
	n = ERB::Util.url_encode (params['splat'][0]).to_s
	fundedProjectsCount = 0
	getProjectIdentifierList(n)['projectIdentifierListArray'].each do |id|
		begin
			fundedProjectsCount = fundedProjectsCount + JSON.parse(RestClient.get  api_simple_log(settings.oipa_api_url + "activities/?format=json&transaction_provider_activity=#{id}&page_size=1&fields=id&ordering=title"))['count'].to_i
		rescue
			puts id
		end
	end
	json :output=> fundedProjectsCount
end

get '/get-funded-projects-page/:page/*?' do
	puts params
	n = ERB::Util.url_encode (params['splat'][0]).to_s
	page = ERB::Util.url_encode params[:page].to_s
	json :output=> get_funded_project_details_page(n, page, 20)
end

get '/get-funding-projects-details/*?' do
	puts params
	n = ERB::Util.url_encode (params['splat'][0]).to_s
	json :output=> get_funding_project_details(n)
end

######################################################################
######################################################################
#Project partners page
get '/projects/*/partners/?' do
	n = ERB::Util.url_encode (params['splat'][0]).to_s
	check_if_project_exists(n)
	# get the project data from the API
	#n = sanitize_input(n,"p")
	project = get_h1_project_details(n)

  	#get the country/region data from the API
  	#countryOrRegion = get_country_or_region(n)

  	# get the funding projects from the API
  	# fundingProjectsData = get_funding_project_details(n)
  	# fundingProjects = fundingProjectsData['results'].select {|project| !project['provider_organisation'].nil? }	

	# get the funded projects from the API
#	fundedProjectsData = get_funded_project_details(n)

  	settings.devtracker_page_title = 'Programme '+project['iati_identifier']+' Partners'
	erb :'projects/partners', 
		:layout => :'layouts/layout',
		:locals => {
			oipa_api_url: settings.oipa_api_url,
			project: project,
			#countryOrRegion: countryOrRegion, 			
 			# fundedProjects: fundedProjectsData,
 			# fundedProjectsCount: fundedProjectsData.length,
 			# fundingProjects: fundingProjects,
 			# fundingProjectsCount: fundingProjectsData['count']
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
  	settings.devtracker_page_title = 'Sector Page'
  	erb :'sector/index', 
		:layout => :'layouts/layout',
		 :locals => {
		 	oipa_api_url: settings.oipa_api_url,
 			high_level_sector_list: high_level_sector_list( get_5_dac_sector_data(), "all_sectors", "High Level Code (L1)", "High Level Sector Description")
 		}		
end

# Category Page (e.g. Three Digit DAC Sector) 
get '/sector/:high_level_sector_code/?' do
	# Get the three digit DAC sector data from the API
  	settings.devtracker_page_title = 'Sector '+sanitize_input(params[:high_level_sector_code],"p")+' Page'
  	erb :'sector/categories', 
		:layout => :'layouts/layout',
		 :locals => {
		 	oipa_api_url: settings.oipa_api_url,
 			category_list: sector_parent_data_list( settings.oipa_api_url, "category", "Category (L2)", "Category Name", "High Level Code (L1)", "High Level Sector Description", sanitize_input(params[:high_level_sector_code],"p"), "category")
 		}		
end

# List of all the High level sector projects (e.g. Three Digit DAC Sector) 

# Sector Page (e.g. Five Digit DAC Sector) 
get '/sector/:high_level_sector_code/categories/:category_code/?' do
	# Get the three digit DAC sector data from the API
  	settings.devtracker_page_title = 'Sector Category '+sanitize_input(params[:category_code],"p")+' Page'
  	erb :'sector/sectors', 
		:layout => :'layouts/layout',
		 :locals => {
		 	oipa_api_url: settings.oipa_api_url,
 			sector_list: sector_parent_data_list(settings.oipa_api_url, "sector", "Code (L3)", "Name", "Category (L2)", "Category Name", sanitize_input(params[:high_level_sector_code],"p"), sanitize_input(params[:category_code],"p"))
 		}		
end

#####################################################################
#  COUNTRY REGION & GLOBAL PROJECT MAP PAGES
#####################################################################

#Aid By Location Page
get '/location/country/?' do
  	settings.devtracker_page_title = 'Aid by Location Page'
  	map_data = dfid_country_map_data2()
  	getMaxBudget = map_data[1].sort_by{|k,val| val['budget']}.reverse!.first
  	getMaxBudget = getMaxBudget[1]['budget']
	erb :'location/country/index', 
		:layout => :'layouts/layout',
		:locals => {
			oipa_api_url: settings.oipa_api_url,
			:dfid_country_map_data => 	map_data[0],
			:dfid_country_stats_data => map_data[1],
			:dfid_complete_country_list => dfid_complete_country_list_region_wise_sorted.sort_by{|k| k},
			:dfid_total_country_budget => total_country_budget_location,
			:sectorData => generateCountryData(),
			:countryMapData => getCountryBoundsForLocation(map_data[1]),
			:maxBudget => getMaxBudget
		}
end

# Aid by Region Page
get '/location/regional/?' do 
  	settings.devtracker_page_title = 'Aid by Region Page'
	erb :'location/regional/index', 
		:layout => :'layouts/layout',
		:locals => {
			:oipa_api_url => settings.oipa_api_url,
			:dfid_regional_projects_data => dfid_regional_projects_data("region"),
			:generateRegionData => generateRegionData()	
		}
end

# Aid by Global Page
get '/location/global/?' do
  	settings.devtracker_page_title = 'Aid by Global Page'
	erb :'location/global/index', 
		:layout => :'layouts/layout',
		:locals => {
			:oipa_api_url => settings.oipa_api_url,
			:dfid_global_projects_data => dfid_regional_projects_data("global")
		}
end

#####################################################################
#  SOLR BASED PAGES
#####################################################################

get '/search/?' do
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

post '/search/?' do
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
	didYouMeanData = generate_did_you_mean_data(didYouMeanQuery,'2')
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
		fcdoCountryBudgets: didYouMeanData['dfidCountryBudgets'],
 		fcdoRegionBudgets: didYouMeanData['dfidRegionBudgets'],
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

# get '/solr-regions/:region_code/?' do |n|
# 	n = sanitize_input(n, "p")
# 	query = '('+n+')'
# 	filters = prepareFilters(query.to_s, 'R')
# 	response = solrResponse(query, 'AND activity_status_code:(1 OR 2 OR 3)', 'R', 0, '', '')
# 	if(response['numFound'].to_i > 0)
# 		response = addTotalBudgetWithCurrency(response)
# 	end
# 	settings.devtracker_page_title = 'Search Results For : ' + query
# 	#erb :'search/solrRegions',
# 	erb :'search/solrTemplate',
# 	:layout => :'layouts/layout',
# 	:locals => 
# 	{
# 		oipa_api_url: settings.oipa_api_url,
# 		query: query,
# 		filters: filters,
# 		response: response,
# 		solrConfig: Oj.load(File.read('data/solr-config.json')),
# 		activityStatus: Oj.load(File.read('data/activity_status.json')),
# 		searchType: 'R',
# 		breadcrumbURL: '/location/regional',
# 		breadcrumbText: 'Aid by Location'
# 	}
# end

# get '/solr-countries/:country_code/?' do |n|
# 	n = sanitize_input(n, "p")
# 	query = '('+n+')'
# 	filters = prepareFilters(query.to_s, 'C')
# 	response = solrResponse(query, 'AND activity_status_code:(1 OR 2 OR 3)', 'C', 0, '', '')
# 	if(response['numFound'].to_i > 0)
# 		response = addTotalBudgetWithCurrency(response)
# 	end
# 	settings.devtracker_page_title = 'Search Results For : ' + query
# 	erb :'search/solrTemplate',
# 	:layout => :'layouts/layout',
# 	:locals => 
# 	{
# 		oipa_api_url: settings.oipa_api_url,
# 		query: query,
# 		filters: filters,
# 		response: response,
# 		solrConfig: Oj.load(File.read('data/solr-config.json')),
# 		activityStatus: Oj.load(File.read('data/activity_status.json')),
# 		searchType: 'C',
# 		breadcrumbURL: '/location/country',
# 		breadcrumbText: 'Aid by Location'
# 	}
# end

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
	sectorJsonData = map_sector_data()
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
	filters = prepareFilters(query.to_s, 'S')
	response = solrResponse(query, 'AND activity_status_code:(2)', 'S', 0, '', '')
	if(response['numFound'].to_i > 0)
		response = addTotalBudgetWithCurrency(response)
	end
	settings.devtracker_page_title = 'Sector '+highLevelCode+' Programmes Page'
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
		sector_list: sector_parent_data_list( settings.oipa_api_url, "category", "Category (L2)", "Category Name", "High Level Code (L1)", "High Level Sector Description", sectorData['highLevelCode'], "category"),
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
	sectorJsonData = map_sector_data()
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
		sector_list: sector_parent_data_list(settings.oipa_api_url, "sector", "Code (L3)", "Name", "Category (L2)", "Category Name", sectorData['highLevelCode'], sectorData['categoryCode']),
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
	sectorJsonData = map_sector_data()
	sectorJsonData = sectorJsonData.select {|sector| sector['Code (L3)'] == dac5Code.to_i}.first
	dac5SectorName = sectorJsonData['Name']
	sectorData['sectorName'] = sectorJsonData['Name']
	query = "(" + sectorJsonData['Code (L3)'].to_s + ")"
	filters = prepareFilters(query.to_s, 'S')
	response = solrResponse(query, 'AND activity_status_code:(2)', 'S', 0, '', '')
	if(response['numFound'].to_i > 0)
		response = addTotalBudgetWithCurrency(response)
	end
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
		sector_list: sector_parent_data_list(settings.oipa_api_url, "sector", "Code (L3)", "Name", "Category (L2)", "Category Name", sectorData['highLevelCode'], sectorData['categoryCode']),
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
#  LHS Filters API
#####################################################################

# get '/getCountryFilters/?' do
# 	countryCode = sanitize_input(params['countryCode'],"p")
# 	projectStatus = params['projectStatus']
# 	projectData = generate_project_page_data(generate_api_list('C',countryCode,projectStatus))
# 	projectData['countryAllProjectFilters'] = get_static_filter_list()
# 	projectData["country"] = get_country_code_name(countryCode)
# 	json :output => projectData
# end

# get '/getSectorFilters' do
# 	sectorCode = params['sectorCode']
# 	projectStatus = params['projectStatus']
# 	projectData = generate_project_page_data(generate_api_list('S',sectorCode,projectStatus))
# 	locationFilterData = prepare_location_country_region_data(projectStatus,sectorCode)
# 	projectData["LocationCountries"] = locationFilterData["locationCountryFilters"]
# 	projectData["LocationRegions"] = locationFilterData["locationRegionFilters"]
# 	#json :output => get_sector_projects_json(params['sectorCode'], params['projectStatus'])
# 	json :output => projectData
# end

# get '/getRegionFilters' do
# 	regionCode = params['regionCode']
# 	projectStatus = params['projectStatus']
# 	projectData = generate_project_page_data(generate_api_list('R',regionCode,projectStatus))
# 	projectData['countryAllProjectFilters'] = get_static_filter_list()
# 	#json :output => get_region_projects_json(params['regionCode'], params['projectStatus'])
# 	json :output => projectData
# end

# get '/getFTSFilters' do
# 	query = sanitize_input(params['query'],"a")
# 	projectStatus = params['projectStatus']
# 	projectData = generate_project_page_data(generate_api_list('F',query,projectStatus))
# 	projectData["projects"] = projectData["projects"]["results"]
# 	#json :output => generate_searched_data(sanitize_input(params['query'],"a"), params['projectStatus'])
# 	json :output => projectData
# end

# get '/getOGDFilters' do
# 	ogd = params['ogd']
# 	projectStatus = params['projectStatus']
# 	projectData = generate_project_page_data(generate_api_list('O',ogd,projectStatus))
# 	#json :output => get_ogd_all_projects_data_json(params['ogd'], params['projectStatus'])
# 	projectData['countryAllProjectFilters'] = get_static_filter_list()
# 	json :output => projectData
# end

#Returns the designated API list based on an active project page type - Not needed
# get '/getapiurls' do
# 	apiType = params['apiType']
# 	apiParams = params['apiParams']
# 	projectStatus = params['projectStatus']
# 	json :output => generate_api_list(apiType,apiParams,projectStatus)
# end

############################################################
## Methods for returning LHS filters - Parallel API calls ##
############################################################

#Returns the project list and the budget higher bound
# get '/getProjectListWithBudgetHi' do
# 	apiType = params['apiType']
# 	apiParams = params['apiParams']
# 	projectStatus = params['projectStatus']
# 	apiList = generate_api_list(apiType,apiParams,projectStatus)
# 	json :output => generateProjectListWithBudgetHiBound(apiList[0])
# end

# #Returns the budget higher bound
# get '/getBudgetHi' do
# 	apiType = params['apiType']
# 	apiParams = params['apiParams']
# 	projectStatus = params['projectStatus']
# 	apiList = generate_api_list(apiType,apiParams,projectStatus)
# 	json :output => generateBudgetHiBound(apiList[0])
# end

# #Returns the Sector List for LHS
# get '/getHiLvlSectorList' do
# 	apiType = params['apiType']
# 	apiParams = params['apiParams']
# 	projectStatus = params['projectStatus']
# 	apiList = generate_api_list(apiType,apiParams,projectStatus)
# 	json :output => generateSectorList(apiList[1])
# end

#Returns the LHS start date
# get '/getStartDate' do
# 	apiType = params['apiType']
# 	apiParams = params['apiParams']
# 	projectStatus = params['projectStatus']
# 	apiList = generate_api_list(apiType,apiParams,projectStatus)
# 	json :output => generateProjectStartDate(apiList[2])
# end

#Returns the LHS end date
# get '/getEndDate' do
# 	apiType = params['apiType']
# 	apiParams = params['apiParams']
# 	projectStatus = params['projectStatus']
# 	apiList = generate_api_list(apiType,apiParams,projectStatus)
# 	json :output => generateProjectEndDate(apiList[3])
# end

#Returns the LHS Document List
# get '/getDocumentTypeList' do
# 	apiType = params['apiType']
# 	apiParams = params['apiParams']
# 	projectStatus = params['projectStatus']
# 	apiList = generate_api_list(apiType,apiParams,projectStatus)
# 	json :output => generateDocumentTypeList(apiList[4])
# end

#Returns the LHS Implementing Org List
# get '/getImplOrgList' do
# 	apiType = params['apiType']
# 	apiParams = params['apiParams']
# 	projectStatus = params['projectStatus']
# 	apiList = generate_api_list(apiType,apiParams,projectStatus)
# 	json :output => generateImplOrgList(apiList[5])
# end

# #Returns the LHS Reporting Org List
# get '/getReportingOrgList' do
# 	apiType = params['apiType']
# 	apiParams = params['apiParams']
# 	projectStatus = params['projectStatus']
# 	apiList = generate_api_list(apiType,apiParams,projectStatus)
# 	if(apiType == 'C')
# 		json :output => generateReportingOrgList(apiList[7])
# 	else
# 		json :output => generateReportingOrgList(apiList[6])
# 	end
# end

#Returns the LHS Filters (Sector Page Specific)
# get '/getSectorSpecificFilters' do
# 	sectorCode = params['sectorCode']
# 	projectStatus = params['projectStatus']
# 	locationFilterData = prepare_location_country_region_data(projectStatus,sectorCode)
# 	sectorData = {}
# 	sectorData["LocationCountries"] = locationFilterData["locationCountryFilters"]
# 	sectorData["LocationRegions"] = locationFilterData["locationRegionFilters"]
# 	json :output => sectorData
# end

# FTS API call wrapper

# get '/getFTSResponse' do
# 	searchQuery = params['searchQuery']
# 	activity_status = params['activity_status']
# 	ordering = params['ordering']
# 	budgetLowerBound = params['budgetLowerBound']
# 	budgetHigherBound = params['budgetHigherBound']
# 	actual_start_date_gte = params['actual_start_date_gte']
# 	planned_end_date_lte = params['planned_end_date_lte']
# 	sector = params['sector']
# 	document_link_category = params['document_link_category']
# 	participating_organisation = params['participating_organisation']
# 	if params['page'] != nil && params['page'] != ''
# 		jsonResponse = RestClient.get  api_simple_log(settings.oipa_api_url + 'activities/?hierarchy=1&page_size=20&format=json&fields=activity_dates,aggregations,activity_status,id,iati_identifier,url,title,reporting_organisation,activity_plus_child_aggregation,descriptions&q='+searchQuery+'&activity_status='+activity_status+'&ordering='+ordering+'&total_hierarchy_budget_gte='+budgetLowerBound+'&total_hierarchy_budget_lte='+budgetHigherBound+'&actual_start_date_gte='+actual_start_date_gte+'&planned_end_date_lte='+planned_end_date_lte+'&sector='+sector+'&document_link_category='+document_link_category +'&participating_organisation='+participating_organisation+'&page='+params['page'])
# 	else
# 		jsonResponse = RestClient.get  api_simple_log(settings.oipa_api_url + 'activities/?hierarchy=1&page_size=20&format=json&fields=activity_dates,aggregations,activity_status,id,iati_identifier,url,title,reporting_organisation,activity_plus_child_aggregation,descriptions&q='+searchQuery+'&activity_status='+activity_status+'&ordering='+ordering+'&total_hierarchy_budget_gte='+budgetLowerBound+'&total_hierarchy_budget_lte='+budgetHigherBound+'&actual_start_date_gte='+actual_start_date_gte+'&planned_end_date_lte='+planned_end_date_lte+'&sector='+sector+'&document_link_category='+document_link_category +'&participating_organisation='+participating_organisation)
# 	end
# 	jsonResponse = Oj.load(jsonResponse)
# 	jsonResponse['results'].each do |r|
# 		r['activity_plus_child_aggregation']['totalBudget'] = Money.new(r['activity_plus_child_aggregation']['activity_children']['budget_value'].to_i*100, 
#                                     if r['activity_plus_child_aggregation']['activity_children']['budget_currency'].nil?  
#                                         if r['activity_plus_child_aggregation']['activity_children']['incoming_funds_currency'].nil?
#                                             if r['activity_plus_child_aggregation']['activity_children']['expenditure_currency'].nil?
#                                                 'GBP'
#                                             else
#                                                 r['activity_plus_child_aggregation']['activity_children']['expenditure_currency']
#                                             end
#                                         else
#                                             r['activity_plus_child_aggregation']['activity_children']['incoming_funds_currency']
#                                         end
#                                     else r['activity_plus_child_aggregation']['activity_children']['budget_currency'] 
#                                     end
#                                         ).round.format(:no_cents_if_whole => true,:sign_before_symbol => false)
# 	end
# 	json :output => jsonResponse
# end
#####################################################################
#  CSV HANDLER
#####################################################################


get '/downloadCSV/:proj_id/:transaction_type?' do
	projID = sanitize_input(params[:proj_id],"newId")
	transactionType = sanitize_input(params[:transaction_type],"p")
	transactionsForCSV = convert_transactions_for_csv(projID,transactionType)
	tempTransactions = transaction_data_hash_table_for_csv(transactionsForCSV,transactionType,projID)
	tempTitle = transactionsForCSV.first
	content_type 'text/csv'
	if transactionType != '0'
		attachment "Export-" +tempTitle['transaction_type']['name']+ "s.csv"
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

#####################################################################
#  TEST PAGES
#####################################################################

get '/test01' do  #homepage
	#read static data from JSON files for the front page
	liveURL = 'https://devtracker-entry.oipa.nl/api/activities/?hierarchy=1&format=json&reporting_organisation_identifier=GB-GOV-15,GB-GOV-9,GB-GOV-6,GB-GOV-2,GB-GOV-1,GB-1,GB-GOV-3,GB-GOV-13,GB-GOV-7,GB-GOV-50,GB-GOV-52,GB-6,GB-10,GB-GOV-10,GB-9,GB-GOV-8,GB-GOV-5,GB-GOV-12,GB-COH-RC000346,GB-COH-03877777,GB-GOV-24&page_size=149&fields=activity_plus_child_aggregation,aggregations&activity_status=1,2,3,4,5&ordering=-activity_plus_child_budget_value&recipient_country=BD'
	solrURL = 'https://fcdo.iati.cloud//search/activity/?q=hierarchy:1%20AND%20participating_org_ref:GB-*%20AND%20recipient_country_code:(BD)%20AND%20reporting_org_ref:(GB-GOV-15%20OR%20GB-GOV-9%20OR%20GB-GOV-6%20OR%20GB-GOV-2%20OR%20GB-GOV-1%20OR%20GB-1%20OR%20GB-GOV-3%20OR%20GB-GOV-13%20OR%20GB-GOV-7%20OR%20GB-GOV-50%20OR%20GB-GOV-52%20OR%20GB-6%20OR%20GB-10%20OR%20GB-GOV-10%20OR%20GB-9%20OR%20GB-GOV-8%20OR%20GB-GOV-5%20OR%20GB-GOV-12%20OR%20GB-COH-RC000346%20OR%20GB-COH-03877777)AND%20activity_status_code:(1%20OR%202%20OR%203%20OR%204%20OR%205)&rows=149&fl=iati_identifier,%20child_aggregation_*,%20activity_plus_child_aggregation*,%20activity_aggregation_*&start=0'
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

get '/faq/?' do
  	settings.devtracker_page_title = 'FAQ: What does this mean?'
	erb :'faq/faq', :layout => :'layouts/layout', :locals => {oipa_api_url: settings.oipa_api_url }
end 

# get '/feedback/?' do
#   	settings.devtracker_page_title = 'Feedback Page'
# 	erb :'feedback/index', :layout => :'layouts/layout_forms',
# 	:locals => {
# 		googlePublicKey: settings.google_recaptcha_publicKey,
# 		oipa_api_url: settings.oipa_api_url
# 	}
# end 

get '/whats-new/?' do
  	settings.devtracker_page_title = "What's New Page"
	erb :'about/whats-new', :layout => :'layouts/layout', :locals => {oipa_api_url: settings.oipa_api_url}
end 

# post '/feedback/index' do
#   	status = verify_google_recaptcha(settings.google_recaptcha_privateKey,sanitize_input(params[:captchaResponse],"a"))
# 	if status == true
# 		Pony.mail({
# 			:from => "devtracker-feedback@fcdo.gov.uk",
# 		    :to => "devtracker-feedback@fcdo.gov.uk",
# 		    :subject => "DevTracker Feedback",
# 		    :body => "<p>" + sanitize_input(params[:email],"e") + "</p><p>" + sanitize_input(params[:name],"a") + "</p><p>" + sanitize_input(params[:description],"a") + "</p>",
# 		    :via => :smtp,
# 		    :via_options => {
# 		    	:address              => '127.0.0.1',
# 		     	:port                 => '25',
# 		     	:openssl_verify_mode  => OpenSSL::SSL::VERIFY_NONE
# 		    }
# 		})
# 		redirect '/'
# 	else
# 		puts "Failed to send email."
# 		redirect '/'
# 	end
# end

	get '/test-cache?' do
		randomNumber = rand(2)
		puts(randomNumber)
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

#error do
#    redirect to('/')
#end

