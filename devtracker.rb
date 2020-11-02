#dotenv is used to load the sensitive environment variables for devtracker.
require 'dotenv'
Dotenv.load('/etc/platform.conf')

require 'sinatra'
require 'json'
require 'rest-client'
require 'active_support'
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

# Developer Machine: set global settings
# set :oipa_api_url, 'https://devtracker.fcdo.gov.uk/api/'
# set :oipa_api_url, 'https://devtracker-staging.oipa.nl/api/'
# set :bind, '0.0.0.0' # Allows for vagrant pass-through whilst debugging

# Server Machine: set global settings to use varnish cache
set :oipa_api_url, 'http://127.0.0.1:6081/api/'

#set :oipa_api_url, 'https://iatidatastore.iatistandard.org/api/'

#ensures that we can use the extension html.erb rather than just .erb
Tilt.register Tilt::ERBTemplate, 'html.erb'
Money.locale_backend = :i18n

#####################################################################
#  Common Variable Assingment
#####################################################################

set :current_first_day_of_financial_year, first_day_of_financial_year(DateTime.now)
set :current_last_day_of_financial_year, last_day_of_financial_year(DateTime.now)
#set :goverment_department_ids, 'GB-GOV-15,GB-GOV-9,GB-GOV-6,GB-GOV-2,GB-GOV-1,GB-1,GB-GOV-3,GB-GOV-13,GB-GOV-7,GB-GOV-50,GB-GOV-52,GB-6,GB-10,GB-GOV-10,GB-9,GB-GOV-8,GB-GOV-5,GB-GOV-12,GB-COH-RC000346,GB-COH-03877777'
set :goverment_department_ids, 'GB-GOV-1'
set :google_recaptcha_publicKey, ENV["GOOGLE_PUBLIC_KEY"]
set :google_recaptcha_privateKey, ENV["GOOGLE_PRIVATE_KEY"]

set :raise_errors, false
set :show_exceptions, false

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
	tempActivityCount = Oj.load(RestClient.get settings.oipa_api_url + "activities/?format=json&recipient_country="+n+"&reporting_organisation_identifier=#{settings.goverment_department_ids}&page_size=1")
	Benchmark.bm(7) do |x|
	 	x.report("Loading Time: ") {
	 		country = get_country_details(n)
	 		results = get_country_results(n)
			#oipa v3.1
			countrySectorGraphData = get_country_sector_graph_data(RestClient.get settings.oipa_api_url + "budgets/aggregations/?reporting_organisation_identifier=#{settings.goverment_department_ids}&order_by=-value&group_by=sector&aggregations=value&format=json&recipient_country=#{n}")
	 	}
	end
	countryYearWiseBudgets= get_country_region_yearwise_budget_graph_data(RestClient.get settings.oipa_api_url + "budgets/aggregations/?format=json&reporting_organisation_identifier=#{settings.goverment_department_ids}&group_by=budget_period_start_quarter&aggregations=value&recipient_country=#{n}&order_by=budget_period_start_year,budget_period_start_quarter")
	implementingOrgList = getCountryLevelImplOrgs(n,tempActivityCount['count'])
	ogds = Oj.load(File.read('data/OGDs.json'))
	topSixResults = pick_top_six_results(n)
	#Geo Location data of country
	geoJsonData = getCountryBounds(n)
	# Get a list of map markers
	mapMarkers = getCountryMapMarkers(n)
	countryBudgetBarGraphData = budgetBarGraphData("budgets/aggregations/?format=json&reporting_organisation_identifier=#{settings.goverment_department_ids}&group_by=reporting_organisation,budget_period_start_quarter&aggregations=value&recipient_country=#{n}&order_by=budget_period_start_year,budget_period_start_quarter")
	#countryBudgetBarGraphDataD = budgetBarGraphDataD("http://d-portal.org/dquery?sql=SELECT%20reporting_ref%20as%20reporting_organisation%20%2C%20EXTRACT(QUARTER%20FROM%20TO_TIMESTAMP(budget_day_start*24*60*60.0))%20as%20budget_period_start_quarter%2C%20EXTRACT(YEAR%20FROM%20TO_TIMESTAMP(budget_day_start*24*60*60.0))%20as%20budget_period_start_year%20%2C%20SUM(budget_gbp)%20AS%20value%20FROM%20act%20JOIN%20budget%20USING%20(aid)%20WHERE%20reporting_ref%20in%20(%27GB-GOV-15%27%2C%27GB-GOV-9%27%2C%27GB-GOV-6%27%2C%27GB-GOV-2%27%2C%27GB-GOV-1%27%2C%27GB-1%27%2C%27GB-GOV-3%27%2C%27GB-GOV-13%27%2C%27GB-GOV-7%27%2C%27GB-GOV-50%27%2C%27GB-GOV-52%27%2C%27GB-6%27%2C%27GB-10%27%2C%27GB-GOV-10%27%2C%27GB-9%27%2C%27GB-GOV-8%27%2C%27GB-GOV-5%27%2C%27GB-GOV-12%27%2C%27GB-COH-RC000346%27%2C%27GB-COH-03877777%27)%20AND%20flags%20%3D%200%20AND%20budget_priority%20%3D%201%20AND%20budget_country%20%3D%20%27#{n}%27%20GROUP%20BY%20budget_period_start_quarter%2C%20budget_period_start_year%2Cbudget_country%2Creporting_ref")
	#puts countryBudgetBarGraphDataD
  	settings.devtracker_page_title = 'Country ' + country[:name] + ' Summary Page'
	erb :'countries/country', 
		:layout => :'layouts/layout',
		:locals => {
 			country: country,
 			countryYearWiseBudgets: countryYearWiseBudgets,
 			countrySectorGraphData: countrySectorGraphData,
 			results: results,
 			topSixResults: topSixResults,
 			oipa_api_url: settings.oipa_api_url,
 			activityCount: tempActivityCount['count'],
 			implementingOrgList: implementingOrgList,
 			countryGeoJsonData: geoJsonData,
			mapMarkers: mapMarkers,
			chartDataRepOrgs: countryBudgetBarGraphData[0],
			chartDataFinYears: countryBudgetBarGraphData[1],
			chartDataColumnData: countryBudgetBarGraphData[2],
			# chartDataRepOrgsD: countryBudgetBarGraphDataD[0],
			# chartDataFinYearsD: countryBudgetBarGraphDataD[1],
			# chartDataColumnDataD: countryBudgetBarGraphDataD[2]
 		}
end

#Country Project List Page
get '/countries/:country_code/projects/?' do |n|
	n = sanitize_input(n,"p").upcase
	projectData = ''
	#projectData = get_country_all_projects_data(n)
	projectData = generate_project_page_data(generate_api_list('C',n,"2"))
	country = get_country_code_name(n)
  	settings.devtracker_page_title = 'Country ' + country[:name] + ' Projects Page'
	erb :'countries/projects', 
		:layout => :'layouts/layout',
		:locals => {
			oipa_api_url: settings.oipa_api_url,
	 		country: country,
	 		total_projects: projectData['projects']['count'],
	 		projects: projectData['projects']['results'],
	 		highLevelSectorList: projectData['highLevelSectorList'],
	 		budgetHigherBound: projectData['project_budget_higher_bound'],
	 		countryAllProjectFilters: get_static_filter_list(),
	 		actualStartDate: projectData['actualStartDate'],
	 		plannedEndDate: projectData['plannedEndDate'],
	 		documentTypes: projectData['document_types'],
	 		implementingOrgTypes: projectData['implementingOrg_types'],
	 		reportingOrgTypes: projectData['reportingOrg_types']
	 	}
		 			
end


#####################################################################
#  GLOBAL PAGES
#####################################################################
# Global all projects page
get '/global' do
	countryAllProjectFilters = get_static_filter_list()
	region = {}
	#Region code can't be left empty. So we are passing an empty string instead. Same goes with the 'region name'.
	#region[:code] = "NS,ZZ"
	region[:code] = "998"
	region[:name] = "All"
	#getRegionProjects = get_region_projects(region[:code])
	getRegionProjects = generate_project_page_data(generate_api_list('R',region[:code],"2"))
  	settings.devtracker_page_title = 'Global All Projects Page'
	erb :'regions/projects-home', 
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
	settings.devtracker_page_title = 'Global '+region[:name]+' Projects Page'
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
# Regions all projects page
get '/regions' do
	countryAllProjectFilters = get_static_filter_list()
	region = {}
	#Region code can't be left empty. So we are passing an empty string instead. Same goes with the 'region name'.
	region[:code] = "298,798,89,589,389,189,679,289,380"
	region[:name] = "All"
	#getRegionProjects = get_region_projects(region[:code])
	getRegionProjects = generate_project_page_data(generate_api_list('R',region[:code],"2"))
  	settings.devtracker_page_title = 'Region '+region[:name]+' Projects Page'
	erb :'regions/projects-home', 
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

# Region summary page
get '/regions/:region_code/?' do |n|
	n = sanitize_input(n,"p")
    region = get_region_details(n)
	#oipa v3.1
	#regionYearWiseBudgets = budgetBarGraphData("budgets/aggregations/?format=json&reporting_organisation_identifier=#{settings.goverment_department_ids}&group_by=reporting_organisation,budget_period_start_quarter&aggregations=value&recipient_region=#{n}&order_by=budget_period_start_year,budget_period_start_quarter")
	regionYearWiseBudgets= get_country_region_yearwise_budget_graph_data(RestClient.get settings.oipa_api_url + "budgets/aggregations/?format=json&reporting_organisation_identifier=#{settings.goverment_department_ids}&group_by=budget_period_start_quarter&aggregations=value&recipient_region=#{n}&order_by=budget_period_start_year,budget_period_start_quarter")
	regionSectorGraphData = get_country_sector_graph_data(RestClient.get settings.oipa_api_url + "budgets/aggregations/?reporting_organisation_identifier=#{settings.goverment_department_ids}&order_by=-value&group_by=sector&aggregations=value&format=json&recipient_region=#{n}")
  	settings.devtracker_page_title = 'Region '+region[:name]+' Summary Page'
	erb :'regions/region', 
		:layout => :'layouts/layout',
		:locals => {
			oipa_api_url: settings.oipa_api_url,
 			region: region,
 			regionYearWiseBudgets: regionYearWiseBudgets,
 			regionSectorGraphData: regionSectorGraphData,
 			mapMarkers: getRegionMapMarkers(region[:code]),
 			#chartDataRepOrgs: regionYearWiseBudgets[0],
			#chartDataFinYears: regionYearWiseBudgets[1],
			#chartDataColumnData: regionYearWiseBudgets[2]
 			#getCountryBoundsForRegions: getCountryBoundsForRegions(getCountryListForRegionMap(region[:name]))
 		}
end


#Region Project List Page
get '/regions/:region_code/projects/?' do |n|
	n = sanitize_input(n,"p")
	countryAllProjectFilters = get_static_filter_list()
	region = get_region_code_name(n)
	#getRegionProjects = get_region_projects(n)
	getRegionProjects = generate_project_page_data(generate_api_list('R',n,"2"))
  	settings.devtracker_page_title = 'Region '+region[:name]+' Projects Page'
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
#  PROJECTS PAGES
#####################################################################

# Project summary page
get '/projects/:proj_id/?' do |n|
	n = sanitize_input(n,"p")
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
  	fundingProjectsCount = get_funding_project_count(n)

	# get the funded projects Count from the API
	fundedProjectsCount = get_funded_project_details(n).length
	#Policy markers
	begin
		getPolicyMarkers = get_policy_markers(n)
	rescue
		getPolicyMarkers = Array.new
	end
	policyMarkerCount = 0
	getPolicyMarkers.each do |marker|
		if(marker['significance']['code'].to_i != 0)
			policyMarkerCount += 1
		end
	end
  	settings.devtracker_page_title = 'Project '+project['iati_identifier']
	erb :'projects/summary', 
		:layout => :'layouts/layout',
		 :locals => {
		 	oipa_api_url: settings.oipa_api_url,
 			project: project,
 			countryOrRegion: countryOrRegion,	 					 			
 			fundedProjectsCount: fundedProjectsCount,
 			fundingProjectsCount: fundingProjectsCount,
 			#projectBudget: projectBudget,
 			projectSectorGraphData: projectSectorGraphData,
 			participatingOrgList: participatingOrgList,
 			policyMarkers: getPolicyMarkers,
 			policyMarkersCount: policyMarkerCount,
 			mapMarkers: getProjectMapMarkers(n)
 		}
end

# Project documents page
get '/projects/:proj_id/documents/?' do |n|
	n = sanitize_input(n,"p")
	# get the project data from the API
	project = get_h1_project_details(n)

  	#get the country/region data from the API
  	countryOrRegion = get_country_or_region(n)

  	# get the funding projects Count from the API
  	fundingProjectsCount = get_funding_project_count(n)

	# get the funded projects Count from the API
	fundedProjectsCount = get_funded_project_details(n).length
  	
  	settings.devtracker_page_title = 'Project '+project['iati_identifier']+' Documents'
	erb :'projects/documents', 
		:layout => :'layouts/layout',
		:locals => {
			oipa_api_url: settings.oipa_api_url,
 			project: project,
 			countryOrRegion: countryOrRegion,
 			fundedProjectsCount: fundedProjectsCount,
 			fundingProjectsCount: fundingProjectsCount 
 		}
end

#Project transactions page
get '/projects/:proj_id/transactions/?' do |n|
	n = sanitize_input(n,"p")
	# get the project data from the API
	project = get_h1_project_details(n)
	componentData = get_project_component_data(project)
		
	# get the transactions from the API
  	incomingFunds = get_transaction_details(n,"1")

  	# get the incomingFund transactions from the API
  	commitments = get_transaction_details(n,"2")

  	# get the disbursement transactions from the API
  	disbursements = get_transaction_details(n,"3")

  	# get the expenditure transactions from the API
  	expenditures = get_transaction_details(n,"4")

  	# get the Interest Repayment transactions from the API
  	interestRepayment = get_transaction_details(n,"5")

  	# get the Loan Repayment transactions from the API
  	loanRepayment = get_transaction_details(n,"6")

  	# get the Purchase of Equity transactions from the API
  	purchaseEquity = get_transaction_details(n,"8")

  	# get yearly budget for H1 Activity from the API
	projectYearWiseBudgets= get_project_yearwise_budget(n)

	#get the country/region data from the API
  	countryOrRegion = get_country_or_region(n)

    # get the funding projects Count from the API
  	fundingProjectsCount = get_funding_project_count(n)

	# get the funded projects Count from the API
	fundedProjectsCount = get_funded_project_details(n).length
	
  	settings.devtracker_page_title = 'Project '+project['iati_identifier']+' Transactions'
	erb :'projects/transactions', 
		:layout => :'layouts/layout',
		:locals => {
			oipa_api_url: settings.oipa_api_url,
			project: project,
			countryOrRegion: countryOrRegion,
 			incomingFunds: incomingFunds,
 			commitments: commitments,
 			disbursements: disbursements,
 			expenditures: expenditures,
 			interestRepayments: interestRepayment,
 			loanRepayments: loanRepayment,
 			purchaseEquities: purchaseEquity,
 			projectYearWiseBudgets: projectYearWiseBudgets, 			
 			fundedProjectsCount: fundedProjectsCount,
 			fundingProjectsCount: fundingProjectsCount,
 			components: componentData
 		}
end

#Project partners page
get '/projects/:proj_id/partners/?' do |n|
	# get the project data from the API
	n = sanitize_input(n,"p")
	project = get_h1_project_details(n)

  	#get the country/region data from the API
  	countryOrRegion = get_country_or_region(n)

  	# get the funding projects from the API
  	fundingProjectsData = get_funding_project_details(n)
  	fundingProjects = fundingProjectsData['results'].select {|project| !project['provider_organisation'].nil? }	

	# get the funded projects from the API
	fundedProjectsData = get_funded_project_details(n)

  	settings.devtracker_page_title = 'Project '+project['iati_identifier']+' Partners'
	erb :'projects/partners', 
		:layout => :'layouts/layout',
		:locals => {
			oipa_api_url: settings.oipa_api_url,
			project: project,
			countryOrRegion: countryOrRegion, 			
 			fundedProjects: fundedProjectsData,
 			fundedProjectsCount: fundedProjectsData.length,
 			fundingProjects: fundingProjects,
 			fundingProjectsCount: fundingProjectsData['count']
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
get '/sector/:high_level_sector_code/projects/?' do
	countryAllProjectFilters = get_static_filter_list()
	sectorData = {}
	sectorData['highLevelCode'] = sanitize_input(params[:high_level_sector_code],"p")
	sectorData['sectorCode'] = ""
	sectorJsonData = map_sector_data()
	sectorJsonData = sectorJsonData.select {|sector| sector['High Level Code (L1)'] == sectorData['highLevelCode'].to_i}
	sectorJsonData.each do |sdata|
		sectorData['sectorCode'].concat(sdata['Code (L3)'].to_s + ",")
	end
	sectorData['categoryCode'] = ""
	sectorData['sectorName'] = ""
	#getSectorProjects = get_sector_projects(sectorData['sectorCode'])
	getSectorProjects = generate_project_page_data(generate_api_list('S',sectorData['sectorCode'],"2"))
	locationFilterData = prepare_location_country_region_data("2",sectorData['sectorCode'])
  	settings.devtracker_page_title = 'Sector '+sectorData['highLevelCode']+' Projects Page'
  	erb :'sector/projects', 
		:layout => :'layouts/layout',
		 :locals => {
		 	oipa_api_url: settings.oipa_api_url,
 			sector_list: sector_parent_data_list( settings.oipa_api_url, "category", "Category (L2)", "Category Name", "High Level Code (L1)", "High Level Sector Description", sectorData['highLevelCode'], "category"),
 			sectorData: sectorData,
 			locationCountryFilters: locationFilterData["locationCountryFilters"],
 			locationRegionFilters: locationFilterData["locationRegionFilters"],
 			countryAllProjectFilters: countryAllProjectFilters,
 			total_projects: getSectorProjects['projects']['count'],
	 		projects: getSectorProjects['projects']['results'],
	 		highLevelSectorList: getSectorProjects['highLevelSectorList'],
	 		budgetHigherBound: getSectorProjects['project_budget_higher_bound'],
	 		actualStartDate: getSectorProjects['actualStartDate'],
 			plannedEndDate: getSectorProjects['plannedEndDate'],
 			documentTypes: getSectorProjects['document_types'],
 			implementingOrgTypes: getSectorProjects['implementingOrg_types'],
 			reportingOrgTypes: getSectorProjects['reportingOrg_types']
 		}	
end

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

# List of all the 3 DAC projects 
get '/sector/:high_level_sector_code/categories/:category_code/projects/?' do
	countryAllProjectFilters = get_static_filter_list()
	sectorData = {}
	sectorData['highLevelCode'] = sanitize_input(params[:high_level_sector_code],"p")
	sectorData['sectorCode'] = ""
	sectorData['categoryCode'] = sanitize_input(params[:category_code],"p")
	sectorJsonData = map_sector_data()
	sectorJsonData = sectorJsonData.select {|sector| sector['Category (L2)'] == sectorData['categoryCode'].to_i}
	sectorJsonData.each do |sdata|
		sectorData['sectorCode'].concat(sdata['Code (L3)'].to_s + ",")
	end
	sectorData['sectorName'] = ""
	#getSectorProjects = get_sector_projects(sectorData['sectorCode'])
	getSectorProjects = generate_project_page_data(generate_api_list('S',sectorData['sectorCode'],"2"))
  	settings.devtracker_page_title = 'Sector Category '+sanitize_input(params[:category_code],"p")+' Projects Page'
  	locationFilterData = prepare_location_country_region_data("2",sectorData['sectorCode'])
  	erb :'sector/projects', 
		:layout => :'layouts/layout',
		 :locals => {
		 	oipa_api_url: settings.oipa_api_url,
 			sector_list: sector_parent_data_list(settings.oipa_api_url, "sector", "Code (L3)", "Name", "Category (L2)", "Category Name", sectorData['highLevelCode'], sectorData['categoryCode']),
 			sectorData: sectorData,
 			locationCountryFilters: locationFilterData["locationCountryFilters"],
 			locationRegionFilters: locationFilterData["locationRegionFilters"],
 			countryAllProjectFilters: countryAllProjectFilters,
 			total_projects: getSectorProjects['projects']['count'],
	 		projects: getSectorProjects['projects']['results'],
	 		highLevelSectorList: getSectorProjects['highLevelSectorList'],
	 		budgetHigherBound: getSectorProjects['project_budget_higher_bound'],
	 		actualStartDate: getSectorProjects['actualStartDate'],
 			plannedEndDate: getSectorProjects['plannedEndDate'],
 			documentTypes: getSectorProjects['document_types'],
 			implementingOrgTypes: getSectorProjects['implementingOrg_types'],
 			reportingOrgTypes: getSectorProjects['reportingOrg_types']
 		}	
end

# Sector All Projects Page (e.g. Five Digit DAC Sector)
get '/sector/:high_level_sector_code/categories/:category_code/projects/:sector_code/?' do
	# Get the five digit DAC sector project data from the API
	countryAllProjectFilters = get_static_filter_list()
	sectorData = {}
	sectorData['highLevelCode'] = sanitize_input(params[:high_level_sector_code],"p")
	sectorData['categoryCode'] = sanitize_input(params[:category_code],"p")
	sectorData['sectorCode'] = sanitize_input(params[:sector_code],"p")
	sectorJsonData = map_sector_data()
	sectorJsonData = sectorJsonData.select {|sector| sector['Code (L3)'] == sectorData['sectorCode'].to_i}.first
	sectorData['sectorName'] = sectorJsonData['Name']
	#getSectorProjects = get_sector_projects(sectorData['sectorCode'])
	getSectorProjects = generate_project_page_data(generate_api_list('S',sectorData['sectorCode'],"2"))
  	settings.devtracker_page_title = 'Sector ' + sectorData['sectorCode'] + ' Projects Page'
  	locationFilterData = prepare_location_country_region_data("2",sectorData['sectorCode'])
  	erb :'sector/projects', 
		:layout => :'layouts/layout',
		 :locals => {
		 	oipa_api_url: settings.oipa_api_url,
 			sector_list: sector_parent_data_list(settings.oipa_api_url, "sector", "Code (L3)", "Name", "Category (L2)", "Category Name", sectorData['highLevelCode'], sectorData['categoryCode']),
 			sectorData: sectorData,
 			locationCountryFilters: locationFilterData["locationCountryFilters"],
 			locationRegionFilters: locationFilterData["locationRegionFilters"],
 			countryAllProjectFilters: countryAllProjectFilters,
 			total_projects: getSectorProjects['projects']['count'],
	 		projects: getSectorProjects['projects']['results'],
	 		highLevelSectorList: getSectorProjects['highLevelSectorList'],
	 		budgetHigherBound: getSectorProjects['project_budget_higher_bound'],
	 		actualStartDate: getSectorProjects['actualStartDate'],
 			plannedEndDate: getSectorProjects['plannedEndDate'],
 			documentTypes: getSectorProjects['document_types'],
 			implementingOrgTypes: getSectorProjects['implementingOrg_types'],
 			reportingOrgTypes: getSectorProjects['reportingOrg_types']
 		}		
end

#####################################################################
#  COUNTRY REGION & GLOBAL PROJECT MAP PAGES
#####################################################################

#Aid By Location Page
get '/location/country/?' do
  	settings.devtracker_page_title = 'Aid by Location Page'
  	map_data = dfid_country_map_data()
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
#  Search PAGE
#####################################################################

get '/search/?' do
	countryAllProjectFilters = get_static_filter_list()
	query = sanitize_input(params['query'],"a")
	includeClosed = sanitize_input(params['includeClosed'],"a")
	activityStatusList = ''
	if(includeClosed == "1") then 
		activityStatusList = '1,2,3,4'
	else
		includeClosed = 0
		activityStatusList = '2'
	end
	#results = generate_searched_data(query,activityStatusList)
	results = generate_project_page_data(generate_api_list('F',query,activityStatusList))
	didYouMeanData = generate_did_you_mean_data(query,activityStatusList)
  	settings.devtracker_page_title = 'Search Results For : ' + query
	erb :'search/search',
	:layout => :'layouts/layout',
	:locals => {
		oipa_api_url: settings.oipa_api_url,
		:query => query,
		includeClosed: includeClosed,
		dfidCountryBudgets: didYouMeanData['dfidCountryBudgets'],
		dfidRegionBudgets: didYouMeanData['dfidRegionBudgets'],
		countryAllProjectFilters: countryAllProjectFilters,
		projects: results['projects']['results'],
		project_count: results['projects']['count'],
		budgetHigherBound: results['project_budget_higher_bound'],
		highLevelSectorList: results['highLevelSectorList'],
		actualStartDate: results['actualStartDate'],
 		plannedEndDate: results['plannedEndDate'],
 		documentTypes: results['document_types'],
 		implementingOrgTypes: results['implementingOrg_types'],
 		reportingOrgTypes: results['reportingOrg_types']
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

get '/getCountryFilters/?' do
	countryCode = sanitize_input(params['countryCode'],"p")
	projectStatus = params['projectStatus']
	projectData = generate_project_page_data(generate_api_list('C',countryCode,projectStatus))
	projectData['countryAllProjectFilters'] = get_static_filter_list()
	projectData["country"] = get_country_code_name(countryCode)
	json :output => projectData
end

get '/getSectorFilters' do
	sectorCode = params['sectorCode']
	projectStatus = params['projectStatus']
	projectData = generate_project_page_data(generate_api_list('S',sectorCode,projectStatus))
	locationFilterData = prepare_location_country_region_data(projectStatus,sectorCode)
	projectData["LocationCountries"] = locationFilterData["locationCountryFilters"]
	projectData["LocationRegions"] = locationFilterData["locationRegionFilters"]
	#json :output => get_sector_projects_json(params['sectorCode'], params['projectStatus'])
	json :output => projectData
end

get '/getRegionFilters' do
	regionCode = params['regionCode']
	projectStatus = params['projectStatus']
	projectData = generate_project_page_data(generate_api_list('R',regionCode,projectStatus))
	projectData['countryAllProjectFilters'] = get_static_filter_list()
	#json :output => get_region_projects_json(params['regionCode'], params['projectStatus'])
	json :output => projectData
end

get '/getFTSFilters' do
	query = sanitize_input(params['query'],"a")
	projectStatus = params['projectStatus']
	projectData = generate_project_page_data(generate_api_list('F',query,projectStatus))
	projectData["projects"] = projectData["projects"]["results"]
	#json :output => generate_searched_data(sanitize_input(params['query'],"a"), params['projectStatus'])
	json :output => projectData
end

get '/getOGDFilters' do
	ogd = params['ogd']
	projectStatus = params['projectStatus']
	projectData = generate_project_page_data(generate_api_list('O',ogd,projectStatus))
	#json :output => get_ogd_all_projects_data_json(params['ogd'], params['projectStatus'])
	projectData['countryAllProjectFilters'] = get_static_filter_list()
	json :output => projectData
end

#Returns the designated API list based on an active project page type - Not needed
get '/getapiurls' do
	apiType = params['apiType']
	apiParams = params['apiParams']
	projectStatus = params['projectStatus']
	json :output => generate_api_list(apiType,apiParams,projectStatus)
end

############################################################
## Methods for returning LHS filters - Parallel API calls ##
############################################################

#Returns the project list and the budget higher bound
get '/getProjectListWithBudgetHi' do
	apiType = params['apiType']
	apiParams = params['apiParams']
	projectStatus = params['projectStatus']
	apiList = generate_api_list(apiType,apiParams,projectStatus)
	json :output => generateProjectListWithBudgetHiBound(apiList[0])
end

#Returns the budget higher bound
get '/getBudgetHi' do
	apiType = params['apiType']
	apiParams = params['apiParams']
	projectStatus = params['projectStatus']
	apiList = generate_api_list(apiType,apiParams,projectStatus)
	json :output => generateBudgetHiBound(apiList[0])
end

#Returns the Sector List for LHS
get '/getHiLvlSectorList' do
	apiType = params['apiType']
	apiParams = params['apiParams']
	projectStatus = params['projectStatus']
	apiList = generate_api_list(apiType,apiParams,projectStatus)
	json :output => generateSectorList(apiList[1])
end

#Returns the LHS start date
get '/getStartDate' do
	apiType = params['apiType']
	apiParams = params['apiParams']
	projectStatus = params['projectStatus']
	apiList = generate_api_list(apiType,apiParams,projectStatus)
	json :output => generateProjectStartDate(apiList[2])
end

#Returns the LHS end date
get '/getEndDate' do
	apiType = params['apiType']
	apiParams = params['apiParams']
	projectStatus = params['projectStatus']
	apiList = generate_api_list(apiType,apiParams,projectStatus)
	json :output => generateProjectEndDate(apiList[3])
end

#Returns the LHS Document List
get '/getDocumentTypeList' do
	apiType = params['apiType']
	apiParams = params['apiParams']
	projectStatus = params['projectStatus']
	apiList = generate_api_list(apiType,apiParams,projectStatus)
	json :output => generateDocumentTypeList(apiList[4])
end

#Returns the LHS Implementing Org List
get '/getImplOrgList' do
	apiType = params['apiType']
	apiParams = params['apiParams']
	projectStatus = params['projectStatus']
	apiList = generate_api_list(apiType,apiParams,projectStatus)
	json :output => generateImplOrgList(apiList[5])
end

#Returns the LHS Reporting Org List
get '/getReportingOrgList' do
	apiType = params['apiType']
	apiParams = params['apiParams']
	projectStatus = params['projectStatus']
	apiList = generate_api_list(apiType,apiParams,projectStatus)
	if(apiType == 'C')
		json :output => generateReportingOrgList(apiList[7])
	else
		json :output => generateReportingOrgList(apiList[6])
	end
end

#Returns the LHS Filters (Sector Page Specific)
get '/getSectorSpecificFilters' do
	sectorCode = params['sectorCode']
	projectStatus = params['projectStatus']
	locationFilterData = prepare_location_country_region_data(projectStatus,sectorCode)
	sectorData = {}
	sectorData["LocationCountries"] = locationFilterData["locationCountryFilters"]
	sectorData["LocationRegions"] = locationFilterData["locationRegionFilters"]
	json :output => sectorData
end

# FTS API call wrapper

get '/getFTSResponse' do
	searchQuery = params['searchQuery']
	activity_status = params['activity_status']
	ordering = params['ordering']
	budgetLowerBound = params['budgetLowerBound']
	budgetHigherBound = params['budgetHigherBound']
	actual_start_date_gte = params['actual_start_date_gte']
	planned_end_date_lte = params['planned_end_date_lte']
	sector = params['sector']
	document_link_category = params['document_link_category']
	participating_organisation = params['participating_organisation']
	if params['page'] != nil && params['page'] != ''
		jsonResponse = RestClient.get settings.oipa_api_url + 'activities/?hierarchy=1&page_size=20&format=json&fields=activity_dates,aggregations,activity_status,id,iati_identifier,url,title,reporting_organisation,activity_plus_child_aggregation,descriptions&q='+searchQuery+'&activity_status='+activity_status+'&ordering='+ordering+'&total_hierarchy_budget_gte='+budgetLowerBound+'&total_hierarchy_budget_lte='+budgetHigherBound+'&actual_start_date_gte='+actual_start_date_gte+'&planned_end_date_lte='+planned_end_date_lte+'&sector='+sector+'&document_link_category='+document_link_category +'&participating_organisation='+participating_organisation+'&page='+params['page'];
	else
		jsonResponse = RestClient.get settings.oipa_api_url + 'activities/?hierarchy=1&page_size=20&format=json&fields=activity_dates,aggregations,activity_status,id,iati_identifier,url,title,reporting_organisation,activity_plus_child_aggregation,descriptions&q='+searchQuery+'&activity_status='+activity_status+'&ordering='+ordering+'&total_hierarchy_budget_gte='+budgetLowerBound+'&total_hierarchy_budget_lte='+budgetHigherBound+'&actual_start_date_gte='+actual_start_date_gte+'&planned_end_date_lte='+planned_end_date_lte+'&sector='+sector+'&document_link_category='+document_link_category +'&participating_organisation='+participating_organisation;
	end
	jsonResponse = Oj.load(jsonResponse)
	jsonResponse['results'].each do |r|
		r['activity_plus_child_aggregation']['totalBudget'] = Money.new(r['activity_plus_child_aggregation']['activity_children']['budget_value'].to_i*100, 
                                    if r['activity_plus_child_aggregation']['activity_children']['budget_currency'].nil?  
                                        if r['activity_plus_child_aggregation']['activity_children']['incoming_funds_currency'].nil?
                                            if r['activity_plus_child_aggregation']['activity_children']['expenditure_currency'].nil?
                                                'GBP'
                                            else
                                                r['activity_plus_child_aggregation']['activity_children']['expenditure_currency']
                                            end
                                        else
                                            r['activity_plus_child_aggregation']['activity_children']['incoming_funds_currency']
                                        end
                                    else r['activity_plus_child_aggregation']['activity_children']['budget_currency'] 
                                    end
                                        ).round.format(:no_cents_if_whole => true,:sign_before_symbol => false)
	end
	json :output => jsonResponse
end
#####################################################################
#  CSV HANDLER
#####################################################################


get '/downloadCSV/:proj_id/:transaction_type?' do
	projID = sanitize_input(params[:proj_id],"p")
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
	projID = sanitize_input(params[:proj_id],"p")
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

get '/department/:dept_id/?' do
	dept_id = sanitize_input(params[:dept_id],"a")
	# if dept_id == 'DFID'
	# 	redirect '/'
	# end
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
		#projectData = get_ogd_all_projects_data(deptIdentifier)
		projectData = generate_project_page_data(generate_api_list('O',deptIdentifier,"2"))
		if projectData['projects']['count'] == 0
			allActivityStatusProjects = JSON.parse(RestClient.get settings.oipa_api_url + "activities/?hierarchy=1&format=json&reporting_organisation_identifier=#{deptIdentifier}&page_size=10&fields=descriptions,activity_status,iati_identifier,url,title,reporting_organisation,activity_plus_child_aggregation,aggregations&activity_status=1,2,3,4&ordering=-activity_plus_child_budget_value")
			allActivityStatusProjectsCount = allActivityStatusProjects['count']
		end
	else
		projectData = {}
		projectData['projects'] = {}
		projectData['projects']['count'] = 0
 		projectData['projects']['results'] = ''
 		projectData['results'] = ''
 		projectData['highLevelSectorList'] = ''
 		projectData['project_budget_higher_bound'] = ''
 		projectData['actualStartDate'] = ''
 		projectData['plannedEndDate'] = ''
 		projectData['document_types'] = ''
 		projectData['implementingOrg_types'] = ''
 		projectData['reportingOrg_types'] = ''
	end
  	settings.devtracker_page_title = ogds[dept_id]["name"]
	erb :'other-govt-departments/other_govt_departments',
	:layout => :'layouts/layout',
	:locals => {
		oipa_api_url: settings.oipa_api_url,
		ogd_title: settings.devtracker_page_title,
		ogd: deptIdentifier,
		deptName: ogds[dept_id]["name"],
		countryAllProjectFilters: get_static_filter_list(),
 		total_projects: projectData['projects']['count'],
 		projects: projectData['projects']['results'],
 		highLevelSectorList: projectData['highLevelSectorList'],
 		budgetHigherBound: projectData['project_budget_higher_bound'],
 		actualStartDate: projectData['actualStartDate'],
 		plannedEndDate: projectData['plannedEndDate'],
 		documentTypes: projectData['document_types'],
 		implementingOrgTypes: projectData['implementingOrg_types'],
 		allProjectsCount: allActivityStatusProjectsCount,
 		reportingOrgTypes: projectData['reportingOrg_types']
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
	    maker.channel.about = "A breakdown of all the projects that have changed for #{countryName[:name]} on DevTracker in reverse chronological order"
	    maker.channel.title = "FCDO projects feed for #{countryName[:name]}"
	    maker.channel.link = "http://devtracker.fcdo.gov.uk/countries/#{n}/projects/"

	    projects.each do |project|
	      maker.items.new_item do |item|
	        #convert lastUpdatedDatetime to UTC
	        lastUpdatedDateTimeUtc = Time.strptime(project['last_updated_datetime'], '%Y-%m-%dT%H:%M:%S').utc	        
	        item.link = "http://devtracker.fcdo.gov.uk/projects/" + project['iati_identifier'] + "/"
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

