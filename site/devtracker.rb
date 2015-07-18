# devtracker.rb
#require 'rubygems'
#require 'bundler'
#Bundler.setup
require 'sinatra'
require 'json'
require 'rest-client'
#require 'sinatra-partial'

#helpers
require_relative 'helpers/formatters.rb'

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

# http://devtracker.dfid.gov.uk/projects/GB-1-204024/
# http://149.210.176.175/api/activities/GB-1-204024?format=json

get '/projects/:proj_id/' do
	# get the project data from the API
	oipa = RestClient.get 'http://149.210.176.175/api/activities/GB-1-204024?format=json'
  	project = JSON.parse(oipa)
	
	erb :'projects/test', 
		:layout => :'layouts/layout',
		 :locals => {
 			project: project
 		}
end

get '/projects/:proj_id/transactions' do
	# get the project data from the API

	erb :'projects/transactions', 
		:layout => :'layouts/layout'
end

#####################################################################
#  STATIC PAGES
#####################################################################

get '/about' do
	erb :'about/index', :layout => :'layouts/layout'
end

get '/cookies' do
	erb :'cookies/index', :layout => :'layouts/layout'
end  

get '/faq' do
	erb :'faq/index', :layout => :'layouts/layout'
end 

get '/feedback' do
	erb :'feedback/index', :layout => :'layouts/layout'
end 

get '/fraud' do
	erb :'fraud/index', :layout => :'layouts/layout'
end  


