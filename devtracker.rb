# devtracker.rb
#require 'rubygems'
#require 'bundler'
#Bundler.setup
require 'sinatra'
require 'json'
require 'rest-client'
require 'active_support'

#helpers path
require_relative 'helpers/formatters.rb'
require_relative 'helpers/oipa_helpers.rb'
require_relative 'helpers/codelists.rb'
require_relative 'helpers/lookups.rb'
require_relative 'helpers/project_helpers.rb'
require_relative 'helpers/sector_helpers.rb'

#helpers modules
include SectorHelpers

# set global settings
set :oipa_api_url, 'http://dfid-oipa.zz-clients.net/api/'

#ensures that we can use the extension html.erb rather than just .erb
Tilt.register Tilt::ERBTemplate, 'html.erb'

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
 			what_we_do: high_level_sector_list,
 			what_we_achieve: top5results 	
 		}
end

#####################################################################
#  PROJECTS PAGES
#####################################################################

# examples:
#http://devtracker.dfid.gov.uk/projects/GB-1-204024/
# http://dfid-oipa.zz-clients.net/api/activities/GB-1-204024?format=json

# Project summary page
get '/projects/:proj_id/?' do |n|
	
	# get the project data from the API
	oipa = RestClient.get settings.oipa_api_url + "activities/#{n}?format=json"
  	project = JSON.parse(oipa)
	
#  	has_funded_projects = funded_projects.size > 0
	fundedProjectsAPI = RestClient.get "http://dfid-oipa.zz-clients.net/api/activities?format=json&transaction_provider_activity=#{n}&page_size=1000"
	fundedProjects = JSON.parse(fundedProjectsAPI)
	has_funded_projects = fundedProjects['count'] > 0

	erb :'projects/summary', 
		:layout => :'layouts/layout',
		 :locals => {
 			project: project
 			has_funded_projects: has_funded_projects
 		}
end

#Project test page
get '/projects/:proj_id/test/?' do |n|
	# get the project data from the API
	oipa = RestClient.get settings.oipa_api_url + "activities/#{n}?format=json"
  	project = JSON.parse(oipa)
	
	erb :'projects/test', 
		:layout => :'layouts/layout',
		 :locals => {
 			project: project
 		}
end

#Project documents page
get '/projects/:proj_id/documents/?' do |n|
	# get the project data from the API
	oipa = RestClient.get settings.oipa_api_url + "activities/#{n}?format=json"
  	project = JSON.parse(oipa)

	erb :'projects/documents', 
		:layout => :'layouts/layout',
		:locals => {
 			project: project
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

	erb :'projects/transactions', 
		:layout => :'layouts/layout',
		:locals => {
			project: project,
 			transactions: transactions
 		}
end

#Project transactions page (test)
get '/projects/:proj_id/txtest/?' do |n|
	# get the project data from the API
	oipa = RestClient.get settings.oipa_api_url + "activities/#{n}?format=json"
  	project = JSON.parse(oipa)

	# get the transactions from the API
	oipa_tx = RestClient.get settings.oipa_api_url + "activities/#{n}-101/transactions?format=json" #TEST: hard-coding -101
  	tx = JSON.parse(oipa_tx)
  	transactions = tx['results']

	erb :'projects/testtx', 
		:layout => :'layouts/layout',
		:locals => {
			project: project,
 			transactions: transactions
 		}
end

#####################################################################
#  STATIC PAGES
#####################################################################

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


