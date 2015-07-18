# devtracker.rb
#require 'rubygems'
#require 'bundler'
#Bundler.setup
require 'sinatra'
require 'json'
#require 'rest-client'
#require 'sinatra-partial'

#helpers
require_relative 'helpers/formatters.rb'

Tilt.register Tilt::ERBTemplate, 'html.erb'

#set :partial_template_engine, :erb

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

get '/about' do
	erb :'about/index', :layout => :'layouts/layout'
end

get '/faq' do
	erb :'faq/index', :layout => :'layouts/layout'
end  