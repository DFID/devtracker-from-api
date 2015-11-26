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

# Developer Machine: set global settings
set :oipa_api_url, 'http://dfid-oipa.zz-clients.net/api/'

# Server Machine: set global settings
#set :oipa_api_url, 'http://127.0.0.1:6081/api/'

#ensures that we can use the extension html.erb rather than just .erb
Tilt.register Tilt::ERBTemplate, 'html.erb'


#####################################################################
#  Common Variable Assingment
#####################################################################

set :current_first_day_of_financial_year, first_day_of_financial_year(DateTime.now)
set :current_last_day_of_financial_year, last_day_of_financial_year(DateTime.now)


#####################################################################
#  HOME PAGE
#####################################################################

get '/' do  #homepage
	#read static data from JSON files for the front page
	top5results = JSON.parse(File.read('data/top5results.json'))
  	top5countries = get_top_5_countries()
 	erb :index,
 		:layout => :'layouts/layout', 
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
	n = sanitize_input(n,"p")
	country = ''
	results = ''
	countryYearWiseBudgets = ''
	countrySectorGraphData = ''
	Benchmark.bm(7) do |x|
	 	x.report("Loading Time: ") {
	 		country = get_country_details(n)
	 		results = get_country_results(n)
    		countryYearWiseBudgets= get_country_region_yearwise_budget_graph_data(RestClient.get settings.oipa_api_url + "activities/aggregations?format=json&reporting_organisation=GB-1&group_by=budget_per_quarter&aggregations=budget&recipient_country=#{n}&order_by=year,quarter")
			countrySectorGraphData = get_country_sector_graph_data(RestClient.get settings.oipa_api_url + "activities/aggregations?reporting_organisation=GB-1&order_by=-budget&group_by=sector&aggregations=budget&format=json&related_activity_recipient_country=#{n}")
	 	}
	end
	erb :'countries/country', 
		:layout => :'layouts/layout',
		:locals => {
 			country: country,
 			countryYearWiseBudgets: countryYearWiseBudgets,
 			countrySectorGraphData: countrySectorGraphData,
 			results: results
 		}
end

#Country Project List Page
get '/countries/:country_code/projects/?' do |n|
	n = sanitize_input(n,"p")
	projectData = ''
	 Benchmark.bm(7) do |x|
	 	x.report("Loading Time: ") {projectData = get_country_all_projects_data_para(n)}
	end
	#projectData = get_country_all_projects_data_para(n)
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
	 		plannedEndDate: projectData['plannedEndDate']
	 	}
		 			
end

#Country Results Page
get '/countries/:country_code/results/?' do |n|		
	n = sanitize_input(n,"p")
	country = get_country_code_name(n)
	results = get_country_results(n)
	resultsPillar = results_pillar_wise_indicators(n,results)
    totalProjects = get_total_project(RestClient.get settings.oipa_api_url + "activities?reporting_organisation=GB-1&hierarchy=1&related_activity_recipient_country=#{n}&format=json&fields=activity_status&page_size=250")
	
	erb :'countries/results', 
		:layout => :'layouts/layout',
		:locals => {
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
	region[:code] = "NS,ZZ"
	region[:name] = "All"
	getRegionProjects = get_region_projects(region[:code])
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
 			plannedEndDate: getRegionProjects['plannedEndDate']
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
 			plannedEndDate: getRegionProjects['plannedEndDate']
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
 			plannedEndDate: getRegionProjects['plannedEndDate']
		}
end

# Region summary page
get '/regions/:region_code/?' do |n|
	n = sanitize_input(n,"p")
    region = get_region_details(n)	
	regionYearWiseBudgets= get_country_region_yearwise_budget_graph_data(RestClient.get settings.oipa_api_url + "activities/aggregations?format=json&reporting_organisation=GB-1&group_by=budget_per_quarter&aggregations=budget&recipient_region=#{n}&order_by=year,quarter")
	regionSectorGraphData = get_country_sector_graph_data(RestClient.get settings.oipa_api_url + "activities/aggregations?reporting_organisation=GB-1&order_by=-budget&group_by=sector&aggregations=budget&format=json&recipient_region=#{n}")
	
	erb :'regions/region', 
		:layout => :'layouts/layout',
		:locals => {
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
 			plannedEndDate: getRegionProjects['plannedEndDate']
		}	 			
end

#####################################################################
#  PROJECTS PAGES
#####################################################################

# Project summary page
get '/projects/:proj_id/?' do |n|
	n = sanitize_input(n,"p")
	# get the project data from the API
  	project = get_h1_project_details(n)

  	#get the country/region data from the API
  	countryOrRegion = get_country_or_region(n)

  	#get total project budget and spend Data
  	projectBudget = get_project_budget(n)

  	#get project sectorwise graph  data
  	projectSectorGraphData = get_project_sector_graph_data(n)
  	
	# get the funding projects Count from the API
  	fundingProjectsCount = get_funding_project_count(n)

	# get the funded projects Count from the API
	fundedProjectsCount = get_funded_project_count(n)
	
	erb :'projects/summary', 
		:layout => :'layouts/layout',
		 :locals => {
 			project: project,
 			countryOrRegion: countryOrRegion,	 					 			
 			fundedProjectsCount: fundedProjectsCount,
 			fundingProjectsCount: fundingProjectsCount,
 			projectBudget: projectBudget,
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
  	
	erb :'projects/documents', 
		:layout => :'layouts/layout',
		:locals => {
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
  	transactions = get_transaction_details(n)

  	# get yearly budget for H1 Activity from the API
	projectYearWiseBudgets= get_project_yearwise_budget(n)
	
	#get the country/region data from the API
  	countryOrRegion = get_country_or_region(n)

    # get the funding projects Count from the API
  	fundingProjectsCount = get_funding_project_count(n)

	# get the funded projects Count from the API
	fundedProjectsCount = get_funded_project_count(n)
	
	erb :'projects/transactions', 
		:layout => :'layouts/layout',
		:locals => {
			project: project,
			countryOrRegion: countryOrRegion,
 			transactions: transactions,
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

	erb :'projects/partners', 
		:layout => :'layouts/layout',
		:locals => {
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
  	erb :'sector/index', 
		:layout => :'layouts/layout',
		 :locals => {
 			high_level_sector_list: high_level_sector_list( get_5_dac_sector_data(), "all_sectors", "High Level Code (L1)", "High Level Sector Description")
 		}		
end

# Category Page (e.g. Three Digit DAC Sector) 
get '/sector/:high_level_sector_code/?' do
	# Get the three digit DAC sector data from the API
  	erb :'sector/categories', 
		:layout => :'layouts/layout',
		 :locals => {
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
 			plannedEndDate: getSectorProjects['plannedEndDate']
 		}	
end

# Sector Page (e.g. Five Digit DAC Sector) 
get '/sector/:high_level_sector_code/categories/:category_code/?' do
	# Get the three digit DAC sector data from the API
  	erb :'sector/sectors', 
		:layout => :'layouts/layout',
		 :locals => {
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
 			plannedEndDate: getSectorProjects['plannedEndDate']
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
 			plannedEndDate: getSectorProjects['plannedEndDate']
 		}		
end

#####################################################################
#  COUNTRY REGION & GLOBAL PROJECT MAP PAGES
#####################################################################

#Aid By Location Page
get '/location/country/?' do
	erb :'location/country/index', 
		:layout => :'layouts/layout',
		:locals => {
			:dfid_country_map_data => 	dfid_country_map_data,
			:dfid_complete_country_list => 	dfid_complete_country_list
		}
end

# Aid by Region Page
get '/location/regional/?' do 
	erb :'location/regional/index', 
		:layout => :'layouts/layout',
		:locals => {
			:dfid_regional_projects_data => dfid_regional_projects_data("region")			
		}
end

# Aid by Region Page
get '/location/global/?' do 
	erb :'location/global/index', 
		:layout => :'layouts/layout',
		:locals => {
			:dfid_global_projects_data => dfid_regional_projects_data("global")
		}
end

#####################################################################
#  Search PAGE
#####################################################################

get '/search/?' do

	countryAllProjectFilters = get_static_filter_list()
	query = sanitize_input(params['query'],"a")
	results = generate_searched_data(query);
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
 		plannedEndDate: results['plannedEndDate']
	}
end

#####################################################################
#  STATIC PAGES
#####################################################################


get '/department' do 
	erb :'department/department', :layout => :'layouts/layout'
end

get '/about/?' do
	erb :'about/about', :layout => :'layouts/layout'
end

get '/cookies/?' do
	erb :'cookies/index', :layout => :'layouts/layout'
end  

get '/faq/?' do
	erb :'faq/faq', :layout => :'layouts/layout'
end 

get '/feedback/?' do
	erb :'feedback/index', :layout => :'layouts/layout'
end 

post '/feedback/index' do
 Pony.mail({
	:from => "devtracker-feedback@dfid.gov.uk",
    :to => "devtracker-feedback@dfid.gov.uk",
    :subject => "DevTracker Feedback",
    :body => "<p>" + sanitize_input(params[:email],"e") + "</p><p>" + sanitize_input(params[:name],"a") + "</p><p>" + sanitize_input(params[:description],"a") + "</p>",
    :via => :smtp,
    :via_options => {
     :address              => '127.0.0.1',
     :port                 => '25'
     }
    })
    redirect '/' 
end

get '/fraud/?' do
	erb :'fraud/index', :layout => :'layouts/layout'
end  

post '/fraud/index' do
	country = sanitize_input(params[:country],"a")
	project = sanitize_input(params[:project],"a")
	description = sanitize_input(params[:description],"a")
	name = sanitize_input(params[:name],"a")
	email = sanitize_input(params[:email],"e")
	telno = sanitize_input(params[:telno],"t")
 Pony.mail({
	:from => "devtracker-feedback@dfid.gov.uk",
    :to => "devtracker-feedback@dfid.gov.uk",
    :subject => country + " " + project,
    :body => "<p>" + country + "</p>" + "<p>" + project + "</p>" + "<p>" + description + "</p>" + "<p>" + name + "</p>" + "<p>" + email + "</p>" + "<p>" + telno + "</p>",
    :via => :smtp,
    :via_options => {
     :address              => '127.0.0.1',
     :port                 => '25'
     }
    })
    redirect '/' 
end

# 404 Error!
not_found do
  status 404
  erb :'404', :layout => :'layouts/layout'
end
