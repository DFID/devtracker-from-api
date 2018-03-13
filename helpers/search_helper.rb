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

	def generate_searched_data(query,activityStatusList)
		#Initiating a blank hash that will eventually store all the necessary data for populating the search result page
		activityStatusList = activityStatusList
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
		oipa_total_project_budget = RestClient.get settings.oipa_api_url + "budgets/aggregations/?format=json&reporting_organisation=GB-GOV-1&budget_period_start=#{settings.current_first_day_of_financial_year}&budget_period_end=#{settings.current_last_day_of_financial_year}&activity_status="+activityStatusList+"&group_by=recipient_country&aggregations=value&recipient_country="+recipient_countries
		countries_project_budget = JSON.parse_nil(oipa_total_project_budget) # Parsed the returned json data and storing it as a hash
		# This check is necessary to make sure if there really exists a DFID country list matching with the search query else won't try to 
		# parse and store budget data for the 'Did you mean' country data. 
		unless searchedData['dfidCountryBudgets'].empty?
			# Goes through each country specific budget data and checks if there's a budget value for it. If there's one, then converts the budget value
			# into GBP with thousand seperators and stores them in the previously initiated placeholder for the country specific budget value
			countries_project_budget['results'].each do |budgets|
				unless budgets['recipient_country']['code'].nil?
					searchedData['dfidCountryBudgets'][budgets['recipient_country']['code']][0] = Money.new(budgets['value'].to_f*100,"GBP").format(:no_cents_if_whole => true,:sign_before_symbol => false)
				end
			end
		end
		# This json call is pulling the total budget list based on the 'recipient_regions' string previously created
		oipa_selected_regions_budget = RestClient.get settings.oipa_api_url + "budgets/aggregations/?format=json&reporting_organisation=GB-GOV-1&budget_period_start=#{settings.current_first_day_of_financial_year}&budget_period_end=#{settings.current_last_day_of_financial_year}&activity_status="+activityStatusList+"&group_by=recipient_region&aggregations=value&recipient_region="+recipient_regions
		regions_project_budget = JSON.parse_nil(oipa_selected_regions_budget) # Parsed the returned json data and storing it as a hash
		# This check is necessary to make sure if there really exists a DFID region list matching with the search query else won't try to 
		# parse and store budget data for the 'Did you mean' region data.
		unless searchedData['dfidRegionBudgets'].empty?
			# Goes through each region specific budget data and checks if there's a budget value for it. If there's one, then converts the budget value
			# into GBP with thousand seperators and stores them in the previously initiated placeholder for the region specific budget value.
			regions_project_budget['results'].each do |budgets|
				unless budgets['recipient_region']['code'].nil?
					searchedData['dfidRegionBudgets'][budgets['recipient_region']['code']][0] = Money.new(budgets['value'].to_f*100,"GBP").format(:no_cents_if_whole => true,:sign_before_symbol => false)
				end
			end
		end
		# Sample Api call - http://&fields=activity_status,iati_identifier,url,title,reporting_organisations,activity_plus_child_aggregation
		# The following api call returns the projects list based on the search query. The result is returned with data sorted
		# by budget value so that we can get the budget higher bound from a single api call.
		oipa_project_list = RestClient.get settings.oipa_api_url + "activities/?hierarchy=1&format=json&page_size=10&fields=aggregations,descriptions,activity_status,iati_identifier,url,title,reporting_organisations,activity_plus_child_aggregation&q=#{query}&activity_status="+activityStatusList+"&ordering=-activity_plus_child_budget_value&reporting_organisation_startswith=GB"
		projects_list= JSON.parse(oipa_project_list)
		searchedData['projects'] = projects_list['results'] # Storing the returned project list
		# Checking if the returned result count is 0 or not. If not, then store the budget value of the first item from the returned search data.
		unless projects_list['count'] == 0
			unless projects_list['results'][0]['aggregations']['activity_children']['budget_value'].nil?
				searchedData['project_budget_higher_bound'] = projects_list['results'][0]['aggregations']['activity_children']['budget_value']
			end
		end
		searchedData['project_count'] = projects_list['count'] # Stored the project count here
		# This returns the relevant sector list to populate the left hand side sectors filter.
		sectorValuesJSON = RestClient.get settings.oipa_api_url + "activities/aggregations/?format=json&group_by=sector&aggregations=count&q=#{query}&reporting_organisation_startswith=GB&activity_status="+activityStatusList
		searchedData['highLevelSectorList'] = high_level_sector_list_filter( sectorValuesJSON) # Returns the high level sector data with name and codes
		#puts searchedData['highLevelSectorList']
		searchedData['highLevelSectorList'] = searchedData['highLevelSectorList'].sort_by {|key| key}

		# Initiating the actual start date and the planned end date.
		searchedData['actualStartDate'] = '1990-01-01T00:00:00'
		searchedData['plannedEndDate'] = '2100-01-01T00:00:00'
		# Pulling json data with an order by on actual start date to get the starting bound for the LHS date range slider. 
		begin	
			searchedData['actualStartDate'] = RestClient.get settings.oipa_api_url + "activities/?format=json&page_size=1&fields=activity_dates&hierarchy=1&q=#{query}&ordering=actual_start_date&start_date_gte=1900-01-02&activity_status="+activityStatusList
			searchedData['actualStartDate'] = JSON.parse(searchedData['actualStartDate'])
			if(searchedData['actualStartDate']['count'] > 0)
				tempStartDate = searchedData['actualStartDate']['results'][0]['activity_dates'].select{|activityDate| activityDate['type']['code'] == '2'}.first
				if (tempStartDate.nil?)
					tempStartDate = searchedData['actualStartDate']['results'][0]['activity_dates'].select{|activityDate| activityDate['type']['code'] == '1'}.first
				end
		    	searchedData['actualStartDate'] = tempStartDate
		    	searchedData['actualStartDate'] = searchedData['actualStartDate']['iso_date']
		    else
		    	searchedData['actualStartDate'] = '1990-01-01T00:00:00'
		    end
		rescue
			searchedData['actualStartDate'] = '1990-01-01T00:00:00'
		end
		#unless searchedData['actualStartDate']['results'][0].nil? 
		#	searchedData['actualStartDate'] = searchedData['actualStartDate']['results'][0]['activity_dates'][1]['iso_date']
		#end
		# Pulling json data with an order by on planned end date (DSC) to get the ending bound for the LHS date range slider. 
		begin	
			searchedData['plannedEndDate'] = RestClient.get settings.oipa_api_url + "activities/?format=json&page_size=1&fields=activity_dates&hierarchy=1&q=#{query}&ordering=-planned_end_date&end_date_isnull=False&activity_status="+activityStatusList
			searchedData['plannedEndDate'] = JSON.parse(searchedData['plannedEndDate'])
			#puts "activities/?format=json&page_size=1&fields=activity_dates&hierarchy=1&q=#{query}&ordering=-planned_end_date&end_date_isnull=False"
			if(searchedData['plannedEndDate']['count'] > 0)
				tempEndDate = searchedData['plannedEndDate']['results'][0]['activity_dates'].select{|activityDate| activityDate['type']['code'] == '3'}.first
				if (tempEndDate.nil?)
					tempEndDate = searchedData['plannedEndDate']['results'][0]['activity_dates'].select{|activityDate| activityDate['type']['code'] == '4'}.first
				end
		    	searchedData['plannedEndDate'] = tempEndDate
		    	searchedData['plannedEndDate'] = searchedData['plannedEndDate']['iso_date']
		    else
		    	searchedData['plannedEndDate'] = '2100-01-01T00:00:00'
		    end
		rescue
			searchedData['plannedEndDate'] = '2100-01-01T00:00:00'
		end
		#unless searchedData['plannedEndDate']['results'][0].nil?
		#	if !searchedData['plannedEndDate']['results'][0]['activity_dates'][2].nil?
		#		searchedData['plannedEndDate'] = searchedData['plannedEndDate']['results'][0]['activity_dates'][2]['iso_date']
		#	else
				#This is an issue. For now it's a temporary remedy used to avoid a ruby error but, this needs to be fixed once zz helps out with the api call to return the actual/planned end date.
		#		searchedData['plannedEndDate'] = '2050-12-31T00:00:00'
		#	end
		#end
		#This code is created for generating the left hand side document type filter list
		oipa_document_type_list = RestClient.get settings.oipa_api_url + "activities/aggregations/?format=json&group_by=document_link_category&aggregations=count&reporting_organisation=GB-GOV-1&q=#{query}&activity_status="+activityStatusList
		document_type_list = JSON.parse(oipa_document_type_list)
		searchedData['document_types'] = document_type_list['results']
		searchedData['document_types'] = searchedData['document_types'].sort_by {|key| key["document_link_category"]["name"]}

		#Implementing org type filters
		participatingOrgInfo = JSON.parse(File.read('data/participatingOrgList.json'))
		oipa_implementingOrg_type_list = RestClient.get settings.oipa_api_url + "activities/aggregations/?format=json&group_by=participating_organisation&aggregations=count&reporting_organisation=GB-GOV-1&q=#{query}&hierarchy=1&activity_status="+activityStatusList
		implementingOrg_type_list = JSON.parse(oipa_implementingOrg_type_list)
		searchedData['implementingOrg_types'] = implementingOrg_type_list['results']
		searchedData['implementingOrg_types'].each do |implementingOrgs|
			if implementingOrgs['participating_organisation'].length < 1
				tempImplmentingOrgData = participatingOrgInfo.select{|implementingOrg| implementingOrg['Code'].to_s == implementingOrgs['participating_organisation_ref'].to_s}.first
		   		if tempImplmentingOrgData.nil?
		   			implementingOrgs['participating_organisation_ref'] = 'na'
		   			implementingOrgs['participating_organisation'] = 'na'
		   		else
		   			implementingOrgs['participating_organisation'] = tempImplmentingOrgData['Name']
		   		end
			end
		end
		searchedData['implementingOrg_types'] = searchedData['implementingOrg_types'].sort_by {|key| key["participating_organisation"]}.uniq{|key| key["participating_organisation_ref"]}
		return searchedData
	end

	def get_static_filter_list()
		staticFilterList = Oj.load(File.read('data/countryProjectsFilters.json'))
	end

end