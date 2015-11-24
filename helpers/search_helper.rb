module SearchHelper

	def generate_searched_data(query)
		searchedData = {}
		dfidCountriesInfo = JSON.parse(File.read('data/dfidCountries.json'))
		dfidRegionsInfo = JSON.parse(File.read('data/dfidRegions.json'))
		dfidCountriesResults = ''
		dfidRegionsResults = ''
		dfidCountriesResults = dfidCountriesInfo.select {|result| result['name'].downcase.include? query.downcase}
		dfidRegionsResults = dfidRegionsInfo.select {|result| result['name'].downcase.include? query.downcase}
		recipient_countries = ''
		recipient_regions = ''
		searchedData['dfidCountryBudgets'] = {}
		searchedData['dfidRegionBudgets'] = {}
		searchedData['project_budget_higher_bound'] = 0
		dfidCountriesResults.each do |results|
			recipient_countries.concat(results["code"] + ',');
			searchedData['dfidCountryBudgets'][results["code"]] = {}
			searchedData['dfidCountryBudgets'][results["code"]][0] = 0
			searchedData['dfidCountryBudgets'][results["code"]][1] = results["name"]
		end
		dfidRegionsResults.each do |results|
			recipient_regions.concat(results["code"] + ',');
			searchedData['dfidRegionBudgets'][results["code"]] = {}
			searchedData['dfidRegionBudgets'][results["code"]][0] = 0
			searchedData['dfidRegionBudgets'][results["code"]][1] = results["name"]
		end
		oipa_total_project_budget = RestClient.get settings.oipa_api_url + "activities/aggregations?format=json&reporting_organisation=GB-1&budget_period_start=#{settings.current_first_day_of_financial_year}&budget_period_end=#{settings.current_last_day_of_financial_year}&group_by=recipient_country&aggregations=budget&recipient_country="+recipient_countries
		countries_project_budget = JSON.parse_nil(oipa_total_project_budget)
		unless searchedData['dfidCountryBudgets'].empty?
			countries_project_budget['results'].each do |budgets|
				unless budgets['recipient_country']['code'].nil?
					searchedData['dfidCountryBudgets'][budgets['recipient_country']['code']][0] = Money.new(budgets['budget'].to_f*100,"GBP").format(:no_cents_if_whole => true,:sign_before_symbol => false)
				end
			end
		end
		oipa_selected_regions_budget = RestClient.get settings.oipa_api_url + "activities/aggregations?format=json&reporting_organisation=GB-1&budget_period_start=#{settings.current_first_day_of_financial_year}&budget_period_end=#{settings.current_last_day_of_financial_year}&group_by=recipient_region&aggregations=budget&recipient_region="+recipient_regions
		regions_project_budget = JSON.parse_nil(oipa_selected_regions_budget)
		unless searchedData['dfidRegionBudgets'].empty?
			regions_project_budget['results'].each do |budgets|
				unless budgets['recipient_region']['code'].nil?
					searchedData['dfidRegionBudgets'][budgets['recipient_region']['code']][0] = Money.new(budgets['budget'].to_f*100,"GBP").format(:no_cents_if_whole => true,:sign_before_symbol => false)
				end
			end
		end
		#Sample Api call - http://&fields=activity_status,iati_identifier,url,title,reporting_organisations,activity_aggregations
		oipa_project_list = RestClient.get settings.oipa_api_url + "activities?hierarchy=1&format=json&reporting_organisation=GB-1&page_size=10&fields=description,activity_status,iati_identifier,url,title,reporting_organisations,activity_aggregations&q=#{query}&activity_status=1,2,3,4,5&ordering=-total_plus_child_budget_value"
		projects_list= JSON.parse(oipa_project_list)
		searchedData['projects'] = projects_list['results']
		unless projects_list['count'] == 0
			searchedData['project_budget_higher_bound'] = projects_list['results'][0]['activity_aggregations']['total_plus_child_budget_value']
		end
		searchedData['project_count'] = projects_list['count']
		sectorValuesJSON = RestClient.get settings.oipa_api_url + "activities/aggregations?format=json&reporting_organisation=GB-1&group_by=sector&aggregations=count&q=#{query}"
		searchedData['highLevelSectorList'] = high_level_sector_list_filter( sectorValuesJSON)

		searchedData['actualStartDate'] = '0000-00-00T00:00:00'
		searchedData['plannedEndDate'] = '0000-00-00T00:00:00'
		searchedData['actualStartDate'] = RestClient.get settings.oipa_api_url + "activities?format=json&page_size=1&fields=activity_dates&reporting_organisation=GB-1&hierarchy=1&q=#{query}&ordering=actual_start_date"
			searchedData['actualStartDate'] = JSON.parse(searchedData['actualStartDate'])
		unless searchedData['actualStartDate']['results'][0].nil? 
			searchedData['actualStartDate'] = searchedData['actualStartDate']['results'][0]['activity_dates'][1]['iso_date']
		end
		searchedData['plannedEndDate'] = RestClient.get settings.oipa_api_url + "activities?format=json&page_size=1&fields=activity_dates&reporting_organisation=GB-1&hierarchy=1&q=#{query}&ordering=-planned_end_date"
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