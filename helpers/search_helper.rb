module SearchHelper

=begin

Author: Auninda Rumy Saleque

Method Name: generate_searched_data

Purpose: This method returns the data necessary for populating the free text search results page.

Input:
query - The query string that was searched through the free text search box

Outputs:
Returns a Hash 'searchedData' with the following keys:

- dfidCountryBudgets (Hash)				-	This is a hash with an array inside. This hash stores country codes as keys which matched with the search query string. 
											The country code in return holds an array of country name and country budget if it exists.

- dfidRegionBudgets (Hash)				-	This is a hash with an array inside. This hash stores region codes as keys which matched with the search query string. 
											The region code in return holds an array of region name and regional budget if it exists.

- project_budget_higher_bound (String)	-	This is the value that helps set the maximum budget value needed for the left hand side budget slider filter.

- projects (Hash)						-	This is a hash storing the projects list data relevant to the search query

- project_count (String)				-	This is the number of projects returned based on the search query

- highLevelSectorList (Hash)			-	This returns the sectors list data for the left hand side sectors filter

- actualStartDate (ISO Date)			-	This returns the actual start date for the returned project list which is needed to set the 
											starting bound of the left hand side date range slider filter.

- plannedEndDate (ISO Date)				-	This returns the planned end date for the returned project list which is needed to set the 
											ending bound of the left hand side date range slider filter.
=end

	def generate_searched_data(query)
		#Initiating a blank hash that will eventually store all the necessary data for populating the search result page
		searchedData = {}
		dfidCountriesInfo = JSON.parse(File.read('data/dfidCountries.json')) # Stores all the DFID relevant country codes and names by parsing the relevant json file
		dfidRegionsInfo = JSON.parse(File.read('data/dfidRegions.json')) # Stores all the DFID relevant region codes and names by parsing the relevant json file
		dfidCountriesResults = '' # Initiated an empty variable that will later store only the search query specific DFID country data
		dfidRegionsResults = '' # Initiated an empty variable that will later store only the search query specific DFID country data
		# Filtering and storing only the search query specific DFID country data if there's any
		dfidCountriesResults = dfidCountriesInfo.select {|result| result['name'].downcase.include? query.downcase} # To avoid multi case letters, a downcase option is used.
		# Filtering and storing only the search query specific DFID region data if there's any
		dfidRegionsResults = dfidRegionsInfo.select {|result| result['name'].downcase.include? query.downcase}	# To avoid multi case letters, a downcase option is used.
		# An empty string which will later store relevant country codes in 'BD,GB,NG' format. This will be needed to be
		# passed as input to an api call which will then return only these specific country related total budgets. These budgets will
		# be needed to be shown for the 'Did you mean' part.
		recipient_countries = ''
		# An empty string which will later store relevant region codes in 'LE,289,298' format. This will be needed to be
		# passed as input to an api call which will then return only these specific region related total budgets. These budgets will
		# be needed to be shown for the 'Did you mean' part.
		recipient_regions = ''
		# Initiating two empty hashes which will be used to store the search query specific country and region information (code, name and budget).
		searchedData['dfidCountryBudgets'] = {}
		searchedData['dfidRegionBudgets'] = {}
		# Initiating the project budget higher bound. This will remain 0 if no budget is found or is empty.
		searchedData['project_budget_higher_bound'] = 0
		# The following loop goes through the previously search specific country data hash and does the following.
		dfidCountriesResults.each do |results|
			recipient_countries.concat(results["code"] + ',');	# This is storing the country codes using ',' in a single string.
			searchedData['dfidCountryBudgets'][results["code"]] = {} # Created empty hash and the country code is used as the key
			searchedData['dfidCountryBudgets'][results["code"]][0] = 0 # Initiating the placeholder for the country specific budget value.
			searchedData['dfidCountryBudgets'][results["code"]][1] = results["name"] # Storing the country name
		end
		# The following loop goes through the previously search specific country data hash and does the following.
		dfidRegionsResults.each do |results|
			recipient_regions.concat(results["code"] + ','); # This is storing the region codes using ',' in a single string.
			searchedData['dfidRegionBudgets'][results["code"]] = {} # Created empty hash and the region code is used as the key
			searchedData['dfidRegionBudgets'][results["code"]][0] = 0 # Initiating the placeholder for the region specific budget value.
			searchedData['dfidRegionBudgets'][results["code"]][1] = results["name"] # Storing the region name
		end
		# This json call is pulling the total budget list based on the 'recipient_countries' string previously created
		oipa_total_project_budget = RestClient.get settings.oipa_api_url + "activities/aggregations?format=json&reporting_organisation=GB-1&budget_period_start=#{settings.current_first_day_of_financial_year}&budget_period_end=#{settings.current_last_day_of_financial_year}&group_by=recipient_country&aggregations=budget&recipient_country="+recipient_countries
		countries_project_budget = JSON.parse_nil(oipa_total_project_budget) # Parsed the returned json data and storing it as a hash
		# This check is necessary to make sure if there really exists a DFID country list matching with the search query else won't try to 
		# parse and store budget data for the 'Did you mean' country data. 
		unless searchedData['dfidCountryBudgets'].empty?
			# Goes through each country specific budget data and checks if there's a budget value for it. If there's one, then converts the budget value
			# into GBP with thousand seperators and stores them in the previously initiated placeholder for the country specific budget value
			countries_project_budget['results'].each do |budgets|
				unless budgets['recipient_country']['code'].nil?
					searchedData['dfidCountryBudgets'][budgets['recipient_country']['code']][0] = Money.new(budgets['budget'].to_f*100,"GBP").format(:no_cents_if_whole => true,:sign_before_symbol => false)
				end
			end
		end
		# This json call is pulling the total budget list based on the 'recipient_regions' string previously created
		oipa_selected_regions_budget = RestClient.get settings.oipa_api_url + "activities/aggregations?format=json&reporting_organisation=GB-1&budget_period_start=#{settings.current_first_day_of_financial_year}&budget_period_end=#{settings.current_last_day_of_financial_year}&group_by=recipient_region&aggregations=budget&recipient_region="+recipient_regions
		regions_project_budget = JSON.parse_nil(oipa_selected_regions_budget) # Parsed the returned json data and storing it as a hash
		# This check is necessary to make sure if there really exists a DFID region list matching with the search query else won't try to 
		# parse and store budget data for the 'Did you mean' region data.
		unless searchedData['dfidRegionBudgets'].empty?
			# Goes through each region specific budget data and checks if there's a budget value for it. If there's one, then converts the budget value
			# into GBP with thousand seperators and stores them in the previously initiated placeholder for the region specific budget value.
			regions_project_budget['results'].each do |budgets|
				unless budgets['recipient_region']['code'].nil?
					searchedData['dfidRegionBudgets'][budgets['recipient_region']['code']][0] = Money.new(budgets['budget'].to_f*100,"GBP").format(:no_cents_if_whole => true,:sign_before_symbol => false)
				end
			end
		end
		# Sample Api call - http://&fields=activity_status,iati_identifier,url,title,reporting_organisations,activity_plus_child_aggregation
		# The following api call returns the projects list based on the search query. The result is returned with data sorted
		# by budget value so that we can get the budget higher bound from a single api call.
		oipa_project_list = RestClient.get settings.oipa_api_url + "activities?hierarchy=1&format=json&page_size=10&fields=description,activity_status,iati_identifier,url,title,reporting_organisations,activity_plus_child_aggregation&q=#{query}&activity_status=1,2,3,4,5&ordering=-activity_plus_child_budget_value"
		projects_list= JSON.parse(oipa_project_list)
		searchedData['projects'] = projects_list['results'] # Storing the returned project list
		# Checking if the returned result count is 0 or not. If not, then store the budget value of the first item from the returned search data.
		unless projects_list['count'] == 0
			unless projects_list['results'][0]['activity_plus_child_aggregation']['budget_value'].nil?
				searchedData['project_budget_higher_bound'] = projects_list['results'][0]['activity_plus_child_aggregation']['budget_value']
			end
		end
		searchedData['project_count'] = projects_list['count'] # Stored the project count here
		# This returns the relevant sector list to populate the left hand side sectors filter.
		sectorValuesJSON = RestClient.get settings.oipa_api_url + "activities/aggregations?format=json&group_by=sector&aggregations=count&q=#{query}"
		searchedData['highLevelSectorList'] = high_level_sector_list_filter( sectorValuesJSON) # Returns the high level sector data with name and codes
		# Initiating the actual start date and the planned end date.
		searchedData['actualStartDate'] = '0000-00-00T00:00:00'
		searchedData['plannedEndDate'] = '0000-00-00T00:00:00'
		# Pulling json data with an order by on actual start date to get the starting bound for the LHS date range slider. 
		searchedData['actualStartDate'] = RestClient.get settings.oipa_api_url + "activities?format=json&page_size=1&fields=activity_dates&hierarchy=1&q=#{query}&ordering=actual_start_date"
			searchedData['actualStartDate'] = JSON.parse(searchedData['actualStartDate'])
		unless searchedData['actualStartDate']['results'][0].nil? 
			searchedData['actualStartDate'] = searchedData['actualStartDate']['results'][0]['activity_dates'][1]['iso_date']
		end
		# Pulling json data with an order by on planned end date (DSC) to get the ending bound for the LHS date range slider. 
		searchedData['plannedEndDate'] = RestClient.get settings.oipa_api_url + "activities?format=json&page_size=1&fields=activity_dates&hierarchy=1&q=#{query}&ordering=-planned_end_date"
		searchedData['plannedEndDate'] = JSON.parse(searchedData['plannedEndDate'])
		unless searchedData['plannedEndDate']['results'][0].nil?
			if !searchedData['plannedEndDate']['results'][0]['activity_dates'][2].nil?
				searchedData['plannedEndDate'] = searchedData['plannedEndDate']['results'][0]['activity_dates'][2]['iso_date']
			else
				#This is an issue. For now it's a temporary remedy used to avoid a ruby error but, this needs to be fixed once zz helps out with the api call to return the actual/planned end date.
				searchedData['plannedEndDate'] = '2050-12-31T00:00:00'
			end
		end

		return searchedData
	end

	def get_static_filter_list()
		staticFilterList = Oj.load(File.read('data/countryProjectsFilters.json'))
	end

end