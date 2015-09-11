# devtracker.rb
#require 'rubygems'
#require 'bundler'
#Bundler.setup
require 'sinatra'
require 'json'
require 'rest-client'
require 'active_support'
require 'kramdown'
require 'pony'

#helpers path
require_relative 'helpers/formatters.rb'
require_relative 'helpers/oipa_helpers.rb'
require_relative 'helpers/codelists.rb'
require_relative 'helpers/lookups.rb'
require_relative 'helpers/project_helpers.rb'
require_relative 'helpers/sector_helpers.rb'
require_relative 'helpers/country_helpers.rb'

#Helper Modules
include CountryHelpers
include Formatters
include SectorHelpers
include ProjectHelpers

# Developer Machine: set global settings
#set :oipa_api_url, 'http://dfid-oipa.zz-clients.net/api/'

# Server Machine: set global settings
set :oipa_api_url, 'http://127.0.0.1:6081/api/'

#ensures that we can use the extension html.erb rather than just .erb
Tilt.register Tilt::ERBTemplate, 'html.erb'
#####################################################################
#  Common Variable Assingment
#####################################################################

#####################################################################
#  HOME PAGE
#####################################################################

get '/' do  #homepage
	#read static data from JSON files for the front page
#	top5countries = JSON.parse(File.read('data/top5countries.json'))
	top5sectors = JSON.parse(File.read('data/top5sectors.json'))
	top5results = JSON.parse(File.read('data/top5results.json'))

	countriesJSON = RestClient.get settings.oipa_api_url + "activities/aggregations?reporting_organisation=GB-1&group_by=recipient_country&aggregations=budget&budget_period_start=2015-04-01&budget_period_end=2016-03-31&order_by=-budget&page_size=5"
  	top5countries = JSON.parse(countriesJSON)

 	erb :index, 
 		:layout => :'layouts/layout', 
 		:locals => {
 			top_5_countries: top5countries, 
 			what_we_do: sector_budgets,
 			what_we_achieve: top5results 	
 		}
end

#####################################################################
#  COUNTRY PAGES
#####################################################################
countriesInfo = JSON.parse(File.read('data/countryInfo.json'))

# Country summary page
get '/countries/:country_code/?' do |n|
	current_first_day_of_financial_year = first_day_of_financial_year(DateTime.now)
	current_last_day_of_financial_year = last_day_of_financial_year(DateTime.now)
    country = countriesInfo.select {|country| country['code'] == n}.first
    oipa_total_projects = RestClient.get settings.oipa_api_url + "activities?reporting_organisation=GB-1&hierarchy=1&related_activity_recipient_country=#{n}&format=json"
    total_projects = JSON.parse(oipa_total_projects)
    oipa_active_projects = RestClient.get settings.oipa_api_url + "activities?reporting_organisation=GB-1&hierarchy=1&related_activity_recipient_country=#{n}&activity_status=2&format=json"
    active_projects = JSON.parse(oipa_active_projects)
    oipa_total_project_budgets = RestClient.get settings.oipa_api_url + "activities/aggregations?format=json&reporting_organisation=GB-1&budget_period_start=#{current_first_day_of_financial_year}&budget_period_end=#{current_last_day_of_financial_year}&group_by=recipient_country&aggregations=budget&recipient_country=#{n}"
    total_project_budgets= JSON.parse(oipa_total_project_budgets)
    oipa_year_wise_budgets=RestClient.get settings.oipa_api_url + "activities/aggregations?format=json&reporting_organisation=GB-1&group_by=budget_per_quarter&aggregations=budget&recipient_country=#{n}&order_by=year,quarter"
    year_wise_budgets= JSON.parse(oipa_year_wise_budgets)

	# get the project data from the API
	#oipa = RestClient.get "http://149.210.176.175/api/activities/#{n}?format=json"
  	#project = JSON.parse(oipa)
	
	erb :'countries/country', 
		:layout => :'layouts/layout',
		:locals => {
 			country: country,
 			total_projects: total_projects,
 			active_projects: active_projects,
 			total_project_budgets: total_project_budgets,
 			year_wise_budgets: year_wise_budgets
 		}
end

#Country Project List Page
get '/countries/:country_code/projects/?' do |n|
	#countriesInfo.select {|country| country['code'] == n}.each do |country|		
		country=countriesInfo.select {|country| country['code'] == n}.first
		oipa_total_projects = RestClient.get settings.oipa_api_url + "activities?reporting_organisation=GB-1&hierarchy=1&related_activity_recipient_country=#{n}&format=json"
	    total_projects = JSON.parse(oipa_total_projects)
		oipa_project_list = RestClient.get settings.oipa_api_url + "activities?format=json&reporting_organisation=GB-1&hierarchy=1&related_activity_recipient_country=#{n}&fields=title,descriptions,activity_status,reporting_organisation,iati_identifier,total_child_budgets,participating_organisations,activity_dates&page_size=1000"
		projects_list= JSON.parse(oipa_project_list)
		projects = projects_list['results']
		erb :'countries/projects', 
			:layout => :'layouts/layout',
			:locals => {
		 		country: country,
		 		total_projects: total_projects,
		 		projects: projects
		 		}
		 			
end
#####################################################################
#  PROJECTS PAGES
#####################################################################
# examples:
# http://devtracker.dfid.gov.uk/projects/GB-1-204024/
# http://dfid-oipa.zz-clients.net/api/activities/GB-1-204024?format=json

# Project summary page
get '/projects/:proj_id/?' do |n|
	# get the project data from the API
	oipa = RestClient.get settings.oipa_api_url + "activities/#{n}?format=json"
  	project = JSON.parse(oipa)
	
	# get the funded projects from the API
    fundedProjectsAPI = RestClient.get settings.oipa_api_url + "activities?format=json&transaction_provider_activity=#{n}&page_size=1000"	
	fundedProjectsData = JSON.parse(fundedProjectsAPI)
			
	erb :'projects/summary', 
		:layout => :'layouts/layout',
		 :locals => {
 			project: project, 	 					 			
 			fundedProjectsCount: fundedProjectsData['count']
 		}
end

# Project documents page
get '/projects/:proj_id/documents/?' do |n|
	# get the project data from the API
	oipa = RestClient.get settings.oipa_api_url + "activities/#{n}?format=json"
  	project = JSON.parse(oipa)

    # get the funded projects from the API
    fundedProjectsAPI = RestClient.get settings.oipa_api_url + "activities?format=json&transaction_provider_activity=#{n}&page_size=1000"	
	fundedProjectsData = JSON.parse(fundedProjectsAPI)	
  	
	erb :'projects/documents', 
		:layout => :'layouts/layout',
		:locals => {
 			project: project,
 			fundedProjectsCount: fundedProjectsData['count']   
 		}
end

#Project transactions page
get '/projects/:proj_id/transactions/?' do |n|
	# get the project data from the API
	oipa = RestClient.get settings.oipa_api_url + "activities/#{n}?format=json"
  	project = JSON.parse(oipa)

	# get the transactions from the API
	oipa_tx = RestClient.get settings.oipa_api_url + "activities/#{n}/transactions?format=json" #TEST: for Partner Project
  	tx = JSON.parse(oipa_tx)
  	transactions = tx['results']

    # get the funded projects from the API
    fundedProjectsAPI = RestClient.get settings.oipa_api_url + "activities?format=json&transaction_provider_activity=#{n}&page_size=1000"	
	fundedProjectsData = JSON.parse(fundedProjectsAPI)
	
	erb :'projects/transactions', 
		:layout => :'layouts/layout',
		:locals => {
			project: project,
 			transactions: transactions, 			
 			fundedProjectsCount: fundedProjectsData['count']  
 		}
end

#Project partners page
get '/projects/:proj_id/partners/?' do |n|
	# get the project data from the API
	oipa = RestClient.get settings.oipa_api_url + "activities/#{n}?format=json"
  	project = JSON.parse(oipa)

	# get the funded projects from the API
    fundedProjectsAPI = RestClient.get settings.oipa_api_url + "activities?format=json&transaction_provider_activity=#{n}&page_size=1000"	
	fundedProjectsData = JSON.parse(fundedProjectsAPI)	

	erb :'projects/partners', 
		:layout => :'layouts/layout',
		:locals => {
			project: project, 			
 			fundedProjects: fundedProjectsData['results'],
 			fundedProjectsCount: fundedProjectsData['count']  
 		}
end
#####################################################################
#  STATIC PAGES
#####################################################################

#Aid By Location Page
get '/location/country/?' do
	current_first_day_of_financial_year = first_day_of_financial_year(DateTime.now)
	current_last_day_of_financial_year = last_day_of_financial_year(DateTime.now)
	oipa_countries = RestClient.get settings.oipa_api_url + "activities/aggregations?format=json&reporting_organisation=GB-1&budget_period_start=#{current_first_day_of_financial_year}&budget_period_end=#{current_last_day_of_financial_year}&group_by=recipient_country&aggregations=count,budget&order_by=recipient_country"
  	countries = JSON.parse(oipa_countries)

	erb :'location/country/index', 
		:layout => :'layouts/layout',
		:locals => {
			:countries => countries
		}
end

get '/about/?' do
	erb :'about/index', :layout => :'layouts/layout'
end

get '/cookies/?' do
	erb :'cookies/index', :layout => :'layouts/layout'
end  

get '/faq/?' do
	erb :'faq/index', :layout => :'layouts/layout'
end 

get '/feedback/?' do
	erb :'feedback/index', :layout => :'layouts/layout'
end 

get '/fraud/?' do
	erb :'fraud/index', :layout => :'layouts/layout'
end  

post '/fraud/index' do
 Pony.mail({
	:from => "devtracker-feedback@dfid.gov.uk",
    :to => "devtracker-feedback@dfid.gov.uk",
    :subject => "Report Fraud:" + params[:country],
    :body => params[:description],
    :via => :smtp,
    :via_options => {
     :address              => '127.0.0.1',
     :port                 => '25'
     }
    })
    redirect '/' 
   end

