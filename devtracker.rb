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
require_relative 'helpers/ogd_helper.rb'

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
include OGDHelper

# Developer Machine: set global settings
set :oipa_api_url, 'https://devtracker.dfid.gov.uk/api/'
#set :oipa_api_url, 'http://loadbalancer1-dfid.oipa.nl/api/'
#set :oipa_api_url, 'https://staging-dfid.oipa.nl/api/'
#set :oipa_api_url, 'https://dev-dfid.oipa.nl/api/'

# Server Machine: set global settings to use varnish cache
#set :oipa_api_url, 'http://127.0.0.1:6081/api/'

#ensures that we can use the extension html.erb rather than just .erb
Tilt.register Tilt::ERBTemplate, 'html.erb'


#####################################################################
#  Common Variable Assingment
#####################################################################

set :current_first_day_of_financial_year, first_day_of_financial_year(DateTime.now)
set :current_last_day_of_financial_year, last_day_of_financial_year(DateTime.now)
set :goverment_department_ids, 'GB-GOV-1, GB-1,GB-GOV-3,GB-GOV-13,GB-GOV-7,GB-GOV-52,GB-6,GB-GOV-10,GB-9,GB-GOV-8,GB-GOV-5,GB-GOV-12,GB-COH-RC000346,GB-COH-03877777'

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
  	settings.devtracker_page_title = ''
 	erb :index,
 		:layout => :'layouts/landing', 
 		:locals => {
 			top_5_countries: top5countries, 
 			what_we_do: high_level_sector_list( get_5_dac_sector_data(), "top_five_sectors", "High Level Code (L1)", "High Level Sector Description"), 
 			what_we_achieve: top5results 	
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
	tempActivityCount = Oj.load(RestClient.get settings.oipa_api_url + "activities/?format=json&recipient_country="+n+"&reporting_organisation=GB-GOV-1&page_size=1")
	Benchmark.bm(7) do |x|
	 	x.report("Loading Time: ") {
	 		country = get_country_details(n)
	 		results = get_country_results(n)
	 		#oipa v2.2
    		#countryYearWiseBudgets= get_country_region_yearwise_budget_graph_data(RestClient.get settings.oipa_api_url + "activities/aggregations/?format=json&reporting_organisation=GB-GOV-1&group_by=budget_per_quarter&aggregations=budget&recipient_country=#{n}&order_by=year,quarter")
			#countrySectorGraphData = get_country_sector_graph_data(RestClient.get settings.oipa_api_url + "activities/aggregations/?reporting_organisation=GB-GOV-1&order_by=-budget&group_by=sector&aggregations=budget&format=json&related_activity_recipient_country=#{n}")
			#oipa v3.1
			countryYearWiseBudgets= get_country_region_yearwise_budget_graph_data(RestClient.get settings.oipa_api_url + "budgets/aggregations/?format=json&reporting_organisation=GB-GOV-1&group_by=budget_period_start_quarter&aggregations=value&recipient_country=#{n}&order_by=budget_period_start_year,budget_period_start_quarter")
			countrySectorGraphData = get_country_sector_graph_data(RestClient.get settings.oipa_api_url + "budgets/aggregations/?reporting_organisation=GB-GOV-1&order_by=-value&group_by=sector&aggregations=value&format=json&recipient_country=#{n}")
	 	}
	end
	relevantReportingOrgs = Oj.load(RestClient.get settings.oipa_api_url + "activities/aggregations/?group_by=reporting_organisation&recipient_country=#{n}&aggregations=count&format=json&reporting_organisation=#{settings.goverment_department_ids}")
	topSixResults = pick_top_six_results(n)
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
 			relevantReportingOrgs: relevantReportingOrgs
 		}
end

#Country Project List Page
get '/countries/:country_code/projects/?' do |n|
	n = sanitize_input(n,"p").upcase
	projectData = ''
	projectData = get_country_all_projects_data(n)
#	 Benchmark.bm(7) do |x|
#	 	x.report("Loading Time: ") {projectData = get_country_all_projects_data_para(n)}
#	end
	#projectData = get_country_all_projects_data_para(n)
  	settings.devtracker_page_title = 'Country ' + projectData['country'][:name] + ' Projects Page'
	erb :'countries/projects', 
		:layout => :'layouts/layout',
		:locals => {
			oipa_api_url: settings.oipa_api_url,
	 		country: projectData['country'],
	 		total_projects: projectData['projects']['count'],
	 		projects: projectData['projects']['results'],
	 		results: projectData['results'],
	 		highLevelSectorList: projectData['highLevelSectorList'],
	 		budgetHigherBound: projectData['project_budget_higher_bound'],
	 		countryAllProjectFilters: projectData['countryAllProjectFilters'],
	 		actualStartDate: projectData['actualStartDate'],
	 		plannedEndDate: projectData['plannedEndDate'],
	 		documentTypes: projectData['document_types'],
	 		implementingOrgTypes: projectData['implementingOrg_types'],
	 		projectCount: projectData['projects']['count']
	 	}
		 			
end

#Country Results Page
get '/countries/:country_code/results/?' do |n|		
	n = sanitize_input(n,"p").upcase
	country = get_country_code_name(n)
	results = get_country_results(n)
	resultsPillar = results_pillar_wise_indicators(n,results)
    totalProjects = get_total_project(RestClient.get settings.oipa_api_url + "activities/?reporting_organisation=GB-GOV-1&hierarchy=1&recipient_country=#{n}&format=json&fields=activity_status&page_size=250&activity_status=2")
  	settings.devtracker_page_title = 'Country '+country[:name]+' Results Page'
	erb :'countries/results', 
		:layout => :'layouts/layout',
		:locals => {
			oipa_api_url: settings.oipa_api_url,
	 		country: country,
	 		totalProjects: totalProjects,
	 		results: results,
	 		resultsPillar: resultsPillar
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
	getRegionProjects = get_region_projects(region[:code])
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
 			projectCount: getRegionProjects['projects']['count']
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
	getRegionProjects = get_region_projects(region[:code])
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
 			projectCount: getRegionProjects['projects']['count']
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
	region[:code] = ""
	region[:name] = "All"
	getRegionProjects = get_region_projects(region[:code])
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
 			implementingOrgTypes: getRegionProjects['implementingOrg_types']
		}
end

# Region summary page
get '/regions/:region_code/?' do |n|
	n = sanitize_input(n,"p")
    region = get_region_details(n)
    #oipa v2.2
	#regionYearWiseBudgets= get_country_region_yearwise_budget_graph_data(RestClient.get settings.oipa_api_url + "activities/aggregations/?format=json&reporting_organisation=GB-GOV-1&group_by=budget_per_quarter&aggregations=budget&recipient_region=#{n}&order_by=year,quarter")
	#regionSectorGraphData = get_country_sector_graph_data(RestClient.get settings.oipa_api_url + "activities/aggregations/?reporting_organisation=GB-GOV-1&order_by=-budget&group_by=sector&aggregations=budget&format=json&recipient_region=#{n}")
	#oipa v3.1
	regionYearWiseBudgets= get_country_region_yearwise_budget_graph_data(RestClient.get settings.oipa_api_url + "budgets/aggregations/?format=json&reporting_organisation=GB-GOV-1&group_by=budget_period_start_quarter&aggregations=value&recipient_region=#{n}&order_by=budget_period_start_year,budget_period_start_quarter")
	regionSectorGraphData = get_country_sector_graph_data(RestClient.get settings.oipa_api_url + "budgets/aggregations/?reporting_organisation=GB-GOV-1&order_by=-value&group_by=sector&aggregations=value&format=json&recipient_region=#{n}")
  	settings.devtracker_page_title = 'Region '+region[:name]+' Summary Page'
	erb :'regions/region', 
		:layout => :'layouts/layout',
		:locals => {
			oipa_api_url: settings.oipa_api_url,
 			region: region,
 			regionYearWiseBudgets: regionYearWiseBudgets,
 			regionSectorGraphData: regionSectorGraphData
 		}
end


#Region Project List Page
get '/regions/:region_code/projects/?' do |n|
	n = sanitize_input(n,"p")
	countryAllProjectFilters = get_static_filter_list()
	region = get_region_code_name(n)
	getRegionProjects = get_region_projects(n)
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
 			projectCount: getRegionProjects['projects']['count']
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
  	#get the country/region data from the API
  	countryOrRegion = get_country_or_region(n)

  	#get total project budget and spend Data
  	#projectBudget = get_project_budget(n)

  	#get project sectorwise graph  data
  	
  	projectSectorGraphData = get_project_sector_graph_data(n)
  	
	# get the funding projects Count from the API
  	fundingProjectsCount = get_funding_project_count(n)

	# get the funded projects Count from the API
	fundedProjectsCount = get_funded_project_count(n)
	
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
 			projectSectorGraphData: projectSectorGraphData
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
	fundedProjectsCount = get_funded_project_count(n)
  	
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
	fundedProjectsCount = get_funded_project_count(n)
	
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
 			fundingProjectsCount: fundingProjectsCount 
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
 			fundedProjects: fundedProjectsData['results'],
 			fundedProjectsCount: fundedProjectsData['count'],
 			fundingProjects: fundingProjects,
 			fundingProjectsCount: fundingProjectsData['count']
 		}
end

#####################################################################
#  SECTOR PAGES
#####################################################################
# examples:
# http://devtracker.dfid.gov.uk/sector/

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
	sectorJsonData = Oj.load(File.read('data/sectorHierarchies.json')).select {|sector| sector['High Level Code (L1)'] == sectorData['highLevelCode'].to_i}
	sectorJsonData.each do |sdata|
		sectorData['sectorCode'].concat(sdata['Code (L3)'].to_s + ",")
	end
	sectorData['sectorName'] = ""
	getSectorProjects = get_sector_projects(sectorData['sectorCode'])
  	settings.devtracker_page_title = 'Sector '+sectorData['highLevelCode']+' Projects Page'
  	erb :'sector/projects', 
		:layout => :'layouts/layout',
		 :locals => {
		 	oipa_api_url: settings.oipa_api_url,
 			sector_list: sector_parent_data_list( settings.oipa_api_url, "category", "Category (L2)", "Category Name", "High Level Code (L1)", "High Level Sector Description", sectorData['highLevelCode'], "category"),
 			sectorData: sectorData,
 			total_projects: getSectorProjects['projects']['count'],
	 		projects: getSectorProjects['projects']['results'],
	 		countryAllProjectFilters: countryAllProjectFilters,
	 		highLevelSectorList: getSectorProjects['highLevelSectorList'],
	 		budgetHigherBound: getSectorProjects['project_budget_higher_bound'],
	 		actualStartDate: getSectorProjects['actualStartDate'],
 			plannedEndDate: getSectorProjects['plannedEndDate'],
 			locationCountryFilters: getSectorProjects['LocationCountries'],
 			locationRegionFilters: getSectorProjects['LocationRegions'],
 			documentTypes: getSectorProjects['document_types'],
 			implementingOrgTypes: getSectorProjects['implementingOrg_types']
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
	sectorJsonData = Oj.load(File.read('data/sectorHierarchies.json')).select {|sector| sector['Category (L2)'] == sectorData['categoryCode'].to_i}
	sectorJsonData.each do |sdata|
		sectorData['sectorCode'].concat(sdata['Code (L3)'].to_s + ",")
	end
	sectorData['sectorName'] = ""
	getSectorProjects = get_sector_projects(sectorData['sectorCode'])
  	settings.devtracker_page_title = 'Sector Category '+sanitize_input(params[:category_code],"p")+' Projects Page'
  	erb :'sector/projects', 
		:layout => :'layouts/layout',
		 :locals => {
		 	oipa_api_url: settings.oipa_api_url,
 			sector_list: sector_parent_data_list(settings.oipa_api_url, "sector", "Code (L3)", "Name", "Category (L2)", "Category Name", sectorData['highLevelCode'], sectorData['categoryCode']),
 			sectorData: sectorData,
 			total_projects: getSectorProjects['projects']['count'],
	 		projects: getSectorProjects['projects']['results'],
	 		countryAllProjectFilters: countryAllProjectFilters,
	 		highLevelSectorList: getSectorProjects['highLevelSectorList'],
	 		budgetHigherBound: getSectorProjects['project_budget_higher_bound'],
	 		actualStartDate: getSectorProjects['actualStartDate'],
 			plannedEndDate: getSectorProjects['plannedEndDate'],
 			locationCountryFilters: getSectorProjects['LocationCountries'],
 			locationRegionFilters: getSectorProjects['LocationRegions'],
 			documentTypes: getSectorProjects['document_types'],
 			implementingOrgTypes: getSectorProjects['implementingOrg_types']
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
	sectorJsonData = Oj.load(File.read('data/sectorHierarchies.json')).select {|sector| sector['Code (L3)'] == sectorData['sectorCode'].to_i}.first
	sectorData['sectorName'] = sectorJsonData["Name"]
	getSectorProjects = get_sector_projects(sectorData['sectorCode'])

  	settings.devtracker_page_title = 'Sector ' + sectorData['sectorCode'] + ' Projects Page'
  	erb :'sector/projects', 
		:layout => :'layouts/layout',
		 :locals => {
		 	oipa_api_url: settings.oipa_api_url,
 			sector_list: sector_parent_data_list(settings.oipa_api_url, "sector", "Code (L3)", "Name", "Category (L2)", "Category Name", sectorData['highLevelCode'], sectorData['categoryCode']),
 			sectorData: sectorData,
 			total_projects: getSectorProjects['projects']['count'],
	 		projects: getSectorProjects['projects']['results'],
	 		countryAllProjectFilters: countryAllProjectFilters,
	 		highLevelSectorList: getSectorProjects['highLevelSectorList'],
	 		budgetHigherBound: getSectorProjects['project_budget_higher_bound'],
	 		actualStartDate: getSectorProjects['actualStartDate'],
 			plannedEndDate: getSectorProjects['plannedEndDate'],
 			locationCountryFilters: getSectorProjects['LocationCountries'],
 			locationRegionFilters: getSectorProjects['LocationRegions'],
 			documentTypes: getSectorProjects['document_types'],
 			implementingOrgTypes: getSectorProjects['implementingOrg_types']
 		}		
end

#####################################################################
#  COUNTRY REGION & GLOBAL PROJECT MAP PAGES
#####################################################################

#Aid By Location Page
get '/location/country/?' do
  	settings.devtracker_page_title = 'Aid by Location Page'
	erb :'location/country/index', 
		:layout => :'layouts/layout',
		:locals => {
			oipa_api_url: settings.oipa_api_url,
			:dfid_country_map_data => 	dfid_country_map_data,
			:dfid_complete_country_list => 	dfid_complete_country_list,
			:dfid_total_country_budget => total_country_budget_location
		}
end

# Aid by Region Page
get '/location/regional/?' do 
  	settings.devtracker_page_title = 'Aid by Region Page'
	erb :'location/regional/index', 
		:layout => :'layouts/layout',
		:locals => {
			:oipa_api_url => settings.oipa_api_url,
			:dfid_regional_projects_data => dfid_regional_projects_data("region")			
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
		activityStatusList = '1,2'
	end
	puts activityStatusList
	results = generate_searched_data(query,activityStatusList);
  	settings.devtracker_page_title = 'Search Results For : ' + query
	erb :'search/search',
	:layout => :'layouts/layout',
	:locals => {
		oipa_api_url: settings.oipa_api_url,
		projects: results['projects'],
		project_count: results['project_count'],
		:query => query,
		countryAllProjectFilters: countryAllProjectFilters,
		budgetHigherBound: results['project_budget_higher_bound'],
		highLevelSectorList: results['highLevelSectorList'],
		dfidCountryBudgets: results['dfidCountryBudgets'],
		dfidRegionBudgets: results['dfidRegionBudgets'],
		actualStartDate: results['actualStartDate'],
 		plannedEndDate: results['plannedEndDate'],
 		documentTypes: results['document_types'],
 		implementingOrgTypes: results['implementingOrg_types'],
 		includeClosed: includeClosed
	}
end

#####################################################################
#  OTHER GOVERNMENT DEPARTMENTS
#####################################################################

#Foreign and Commonwealth Office
get '/foreign-and-commonwealth-office' do
	ogdCode = 'GB-3,GB-GOV-3'
	projectData = get_ogd_all_projects_data(ogdCode)
  	settings.devtracker_page_title = 'Foreign and Commonwealth Office Projects Page'
	erb :'other-govt-departments/other_govt_departments',
	:layout => :'layouts/layout',
	:locals => {
		oipa_api_url: settings.oipa_api_url,
		ogd_title: settings.devtracker_page_title,
		ogd: ogdCode,
 		total_projects: projectData['projects']['count'],
 		projects: projectData['projects']['results'],
 		results: projectData['results'],
 		highLevelSectorList: projectData['highLevelSectorList'],
 		budgetHigherBound: projectData['project_budget_higher_bound'],
 		countryAllProjectFilters: projectData['countryAllProjectFilters'],
 		actualStartDate: projectData['actualStartDate'],
 		plannedEndDate: projectData['plannedEndDate'],
 		documentTypes: projectData['document_types'],
 		implementingOrgTypes: projectData['implementingOrg_types'],
 		projectCount: projectData['projects']['count']
	}
end

#Department for Work and Pensions
get '/department-for-work-and-pensions' do
	ogdCode = 'GB-9'
	projectData = get_ogd_all_projects_data(ogdCode)
  	settings.devtracker_page_title = 'Department for Work and Pensions Projects Page'
	erb :'other-govt-departments/other_govt_departments',
	:layout => :'layouts/layout',
	:locals => {
		oipa_api_url: settings.oipa_api_url,
		ogd_title: settings.devtracker_page_title,
		ogd: ogdCode,
 		total_projects: projectData['projects']['count'],
 		projects: projectData['projects']['results'],
 		results: projectData['results'],
 		highLevelSectorList: projectData['highLevelSectorList'],
 		budgetHigherBound: projectData['project_budget_higher_bound'],
 		countryAllProjectFilters: projectData['countryAllProjectFilters'],
 		actualStartDate: projectData['actualStartDate'],
 		plannedEndDate: projectData['plannedEndDate'],
 		documentTypes: projectData['document_types'],
 		implementingOrgTypes: projectData['implementingOrg_types'],
 		projectCount: projectData['projects']['count']
	}
end

#Ministry of Defence
get '/ministry-of-defence' do
	ogdCode = 'GB-GOV-8'
	projectData = get_ogd_all_projects_data(ogdCode)
  	settings.devtracker_page_title = 'Ministry of Defence Projects Page'
	erb :'other-govt-departments/other_govt_departments',
	:layout => :'layouts/layout',
	:locals => {
		oipa_api_url: settings.oipa_api_url,
		ogd_title: settings.devtracker_page_title,
		ogd: ogdCode,
 		total_projects: projectData['projects']['count'],
 		projects: projectData['projects']['results'],
 		results: projectData['results'],
 		highLevelSectorList: projectData['highLevelSectorList'],
 		budgetHigherBound: projectData['project_budget_higher_bound'],
 		countryAllProjectFilters: projectData['countryAllProjectFilters'],
 		actualStartDate: projectData['actualStartDate'],
 		plannedEndDate: projectData['plannedEndDate'],
 		documentTypes: projectData['document_types'],
 		implementingOrgTypes: projectData['implementingOrg_types'],
 		projectCount: projectData['projects']['count']
	}
end

#Department of Energy and Climate Change
get '/department-of-energy-and-climate-change' do
	ogdCode = 'GB-GOV-4'
	projectData = get_ogd_all_projects_data(ogdCode)
  	settings.devtracker_page_title = 'Department of Energy and Climate Change Projects Page'
	erb :'other-govt-departments/other_govt_departments',
	:layout => :'layouts/layout',
	:locals => {
		oipa_api_url: settings.oipa_api_url,
		ogd_title: settings.devtracker_page_title,
		ogd: ogdCode,
 		total_projects: projectData['projects']['count'],
 		projects: projectData['projects']['results'],
 		results: projectData['results'],
 		highLevelSectorList: projectData['highLevelSectorList'],
 		budgetHigherBound: projectData['project_budget_higher_bound'],
 		countryAllProjectFilters: projectData['countryAllProjectFilters'],
 		actualStartDate: projectData['actualStartDate'],
 		plannedEndDate: projectData['plannedEndDate'],
 		documentTypes: projectData['document_types'],
 		implementingOrgTypes: projectData['implementingOrg_types'],
 		projectCount: projectData['projects']['count']
	}
end

#Home Office
get '/home-office' do
	ogdCode = 'GB-6'
	projectData = get_ogd_all_projects_data(ogdCode)
  	settings.devtracker_page_title = 'Home Office Projects Page'
	erb :'other-govt-departments/other_govt_departments',
	:layout => :'layouts/layout',
	:locals => {
		oipa_api_url: settings.oipa_api_url,
		ogd_title: settings.devtracker_page_title,
		ogd: ogdCode,
 		total_projects: projectData['projects']['count'],
 		projects: projectData['projects']['results'],
 		results: projectData['results'],
 		highLevelSectorList: projectData['highLevelSectorList'],
 		budgetHigherBound: projectData['project_budget_higher_bound'],
 		countryAllProjectFilters: projectData['countryAllProjectFilters'],
 		actualStartDate: projectData['actualStartDate'],
 		plannedEndDate: projectData['plannedEndDate'],
 		documentTypes: projectData['document_types'],
 		implementingOrgTypes: projectData['implementingOrg_types'],
 		projectCount: projectData['projects']['count']
	}
end

#Department for Environment Food and Rural Affairs
get '/department-for-environment-food-and-rural-affairs' do
	ogdCode = 'GB-7,GB-GOV-7'
	projectData = get_ogd_all_projects_data(ogdCode)
  	settings.devtracker_page_title = 'Department for Environment Food and Rural Affairs Projects Page'
	erb :'other-govt-departments/other_govt_departments',
	:layout => :'layouts/layout',
	:locals => {
		oipa_api_url: settings.oipa_api_url,
		ogd_title: settings.devtracker_page_title,
		ogd: ogdCode,
 		total_projects: projectData['projects']['count'],
 		projects: projectData['projects']['results'],
 		results: projectData['results'],
 		highLevelSectorList: projectData['highLevelSectorList'],
 		budgetHigherBound: projectData['project_budget_higher_bound'],
 		countryAllProjectFilters: projectData['countryAllProjectFilters'],
 		actualStartDate: projectData['actualStartDate'],
 		plannedEndDate: projectData['plannedEndDate'],
 		documentTypes: projectData['document_types'],
 		implementingOrgTypes: projectData['implementingOrg_types'],
 		projectCount: projectData['projects']['count']
	}
end

#Department of Health
get '/department-of-health' do
	ogdCode = 'GB-10'
	projectData = get_ogd_all_projects_data(ogdCode)
  	settings.devtracker_page_title = 'Department of Health Projects Page'
	erb :'other-govt-departments/other_govt_departments',
	:layout => :'layouts/layout',
	:locals => {
		oipa_api_url: settings.oipa_api_url,
		ogd_title: settings.devtracker_page_title,
		ogd: ogdCode,
 		total_projects: projectData['projects']['count'],
 		projects: projectData['projects']['results'],
 		results: projectData['results'],
 		highLevelSectorList: projectData['highLevelSectorList'],
 		budgetHigherBound: projectData['project_budget_higher_bound'],
 		countryAllProjectFilters: projectData['countryAllProjectFilters'],
 		actualStartDate: projectData['actualStartDate'],
 		plannedEndDate: projectData['plannedEndDate'],
 		documentTypes: projectData['document_types'],
 		implementingOrgTypes: projectData['implementingOrg_types'],
 		projectCount: projectData['projects']['count']
	}
end

#Medical Research Council - (This link does not work at the moment)
get '/medical-research-council' do
	ogdCode = 'GB-COH-RC000346'
	projectData = get_ogd_all_projects_data(ogdCode)
  	settings.devtracker_page_title = 'Medical Research Council'
	erb :'other-govt-departments/other_govt_departments',
	:layout => :'layouts/layout',
	:locals => {
		oipa_api_url: settings.oipa_api_url,
		ogd_title: settings.devtracker_page_title,
		ogd: ogdCode,
 		total_projects: projectData['projects']['count'],
 		projects: projectData['projects']['results'],
 		results: projectData['results'],
 		highLevelSectorList: projectData['highLevelSectorList'],
 		budgetHigherBound: projectData['project_budget_higher_bound'],
 		countryAllProjectFilters: projectData['countryAllProjectFilters'],
 		actualStartDate: projectData['actualStartDate'],
 		plannedEndDate: projectData['plannedEndDate'],
 		documentTypes: projectData['document_types'],
 		implementingOrgTypes: projectData['implementingOrg_types'],
 		projectCount: projectData['projects']['count']
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

#####################################################################
#  STATIC PAGES
#####################################################################


get '/department' do
  	settings.devtracker_page_title = 'Aid by Department Page'
	erb :'department/department', :layout => :'layouts/layout', :locals => {oipa_api_url: settings.oipa_api_url}
end

get '/about/?' do
  	settings.devtracker_page_title = 'About DevTracker Page'
	erb :'about/about', :layout => :'layouts/layout', :locals => {oipa_api_url: settings.oipa_api_url}
end

get '/cookies/?' do
  	settings.devtracker_page_title = 'Cookies Page'
	erb :'cookies/index', :layout => :'layouts/layout', :locals => {oipa_api_url: settings.oipa_api_url}
end  

get '/faq/?' do
  	settings.devtracker_page_title = 'FAQ: What does this mean?'
	erb :'faq/faq', :layout => :'layouts/layout', :locals => {oipa_api_url: settings.oipa_api_url }
end 

get '/feedback/?' do
  	settings.devtracker_page_title = 'Feedback Page'
	erb :'feedback/index', :layout => :'layouts/layout_forms',
	:locals => {
		googlePublicKey: settings.google_recaptcha_publicKey,
		oipa_api_url: settings.oipa_api_url
	}
end 

get '/whats-new/?' do
  	settings.devtracker_page_title = "What's New Page"
	erb :'about/whats-new', :layout => :'layouts/layout', :locals => {oipa_api_url: settings.oipa_api_url}
end 

post '/feedback/index' do
  	status = verify_google_recaptcha(settings.google_recaptcha_privateKey,sanitize_input(params[:captchaResponse],"a"))
	if status == true
		Pony.mail({
			:from => "devtracker-feedback@dfid.gov.uk",
		    :to => "devtracker-feedback@dfid.gov.uk",
		    :subject => "DevTracker Feedback",
		    :body => "<p>" + sanitize_input(params[:email],"e") + "</p><p>" + sanitize_input(params[:name],"a") + "</p><p>" + sanitize_input(params[:description],"a") + "</p>",
		    :via => :smtp,
		    :via_options => {
		    	:address              => '127.0.0.1',
		     	:port                 => '25',
		     	:openssl_verify_mode  => OpenSSL::SSL::VERIFY_NONE
		    }
		})
		redirect '/'
	else
		puts "Failed to send email."
		redirect '/'
	end
end

get '/fraud/?' do
  	settings.devtracker_page_title = "Reporting fraud or corrupt practices Page"
	erb :'fraud/index', :layout => :'layouts/layout_forms',
	:locals => {
		googlePublicKey: settings.google_recaptcha_publicKey,
		oipa_api_url: settings.oipa_api_url
	}
end  

post '/fraud/index' do
	status = verify_google_recaptcha(settings.google_recaptcha_privateKey,sanitize_input(params[:captchaResponse],"a"))
	if status == true
		country = sanitize_input(params[:country],"a")
		project = sanitize_input(params[:project],"a")
		description = sanitize_input(params[:description],"a")
		name = sanitize_input(params[:name],"a")
		email = sanitize_input(params[:email],"e")
		telno = sanitize_input(params[:telno],"t")
	 	Pony.mail({
			:from => "devtracker-feedback@dfid.gov.uk",
		    :to => "reportingconcerns@dfid.gov.uk",
		    :subject => "(Fraud Report): " + country + " - " + project,
		    #:body => "<p>" + country + "</p>" + "<p>" + project + "</p>" + "<p>" + description + "</p>" + "<p>" + name + "</p>" + "<p>" + email + "</p>" + "<p>" + telno + "</p>",
		    :body => "Country: " + country + "\n" + "Project: " + project + "\n" + "Description: \n" + description + "\n \nContact Information: \n" + "Name: " + name + "\n" + "Email: " + email + "\n" + "Telephone Number: " + telno,
		    :via => :smtp,
		    :via_options => {
		    	:address              => '127.0.0.1',
		     	:port                 => '25',
		     	:openssl_verify_mode  => OpenSSL::SSL::VERIFY_NONE
		    }
	    })
	    redirect '/'
	else
		puts "Failed to send email."
		redirect '/'
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
	    maker.channel.about = "A breakdown of all the projects that have changed for #{countryName[:name]} on DevTracker in reverse chronological order"
	    maker.channel.title = "DFID projects feed for #{countryName[:name]}"
	    maker.channel.link = "http://devtracker.dfid.gov.uk/countries/#{n}/projects/"

	    projects.each do |project|
	      maker.items.new_item do |item|
	        #convert lastUpdatedDatetime to UTC
	        lastUpdatedDateTimeUtc = Time.strptime(project['last_updated_datetime'], '%Y-%m-%dT%H:%M:%S').utc	        
	        item.link = "http://devtracker.dfid.gov.uk/projects/" + project['iati_identifier'] + "/"
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

