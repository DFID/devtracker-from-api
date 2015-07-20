# devtracker.rb
#require 'rubygems'
#require 'bundler'
#Bundler.setup
require 'sinatra'
require 'json'
require 'rest-client'
#require 'sinatra-partial'
#require 'money'
require 'active_support'
require 'strftime'

#helpers
require_relative 'helpers/formatters.rb'
require_relative 'helpers/oipa_helpers.rb'
require_relative 'helpers/codelists.rb'
require_relative 'helpers/lookups.rb'
require_relative 'helpers/project_helpers.rb'

Tilt.register Tilt::ERBTemplate, 'html.erb'

#set :partial_template_engine, :erb

#####################################################################
#  HOME PAGE
#####################################################################

get '/' do  #homepage
	top5countries = JSON.parse(File.read('data/top5countries.json'))
	top5sectors = JSON.parse(File.read('data/top5sectors.json'))
	top5results = JSON.parse(File.read('data/top5results.json'))

 	erb :index, 
 		:layout => :'layouts/layout', 
 		:locals => {
 			top_5_countries: top5countries, 
 			what_we_do: top5sectors,
 			what_we_achieve: top5results
 		}
end

#####################################################################
#  PROJECTS PAGES
#####################################################################

# examples:
#http://devtracker.dfid.gov.uk/projects/GB-1-204024/
# http://149.210.176.175/api/activities/GB-1-204024?format=json

# Project summary page
get '/projects/:proj_id/?' do |n|
	# get the project data from the API
	oipa = RestClient.get "http://149.210.176.175/api/activities/#{n}?format=json"
  	project = JSON.parse(oipa)
	
	erb :'projects/summary', 
		:layout => :'layouts/layout',
		 :locals => {
 			project: project
 		}
end

#Project test page
get '/projects/:proj_id/test/?' do |n|
	# get the project data from the API
	oipa = RestClient.get "http://149.210.176.175/api/activities/#{n}?format=json"
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
	oipa = RestClient.get "http://149.210.176.175/api/activities/#{n}?format=json"
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
	oipa = RestClient.get "http://149.210.176.175/api/activities/#{n}?format=json"
  	project = JSON.parse(oipa)

	erb :'projects/transactions', 
		:layout => :'layouts/layout',
		:locals => {
 			project: project
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


