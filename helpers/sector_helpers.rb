module SectorHelpers

	include CommonHelpers
=begin  		
		highLevelSectorBudget = sectorValues.map do |elem| 
	       {  
	       	  code, name, budget = '', '', 0
	       	 
	       	  highLevelSector.find do |source|
	       	  {	 
	       	   	if source["Code (L3)"].to_s == elem["sector"]["code"] then
	       	   		code 		 = source["High Level Code (L1)"]     
			   		name 		 = source["High Level Sector Description"]
               		budget       = elem["budget"] 		
               	 end   		       	  
	       	  }end	

	       	  if code != '' and name != '' and budget != 0 then
	       	  	:code => code,
	       	  	:name => name,
	       	  	:budget => budget	
	       	   end	
	       } 
	     end
=end
	def get_5_dac_sector_data()
		firstDayOfFinYear = first_day_of_financial_year(DateTime.now)
      	lastDayOfFinYear = last_day_of_financial_year(DateTime.now)
		sectorValuesJSON = RestClient.get  api_simple_log(settings.oipa_api_url + "budgets/aggregations/?reporting_organisation_identifier=#{settings.goverment_department_ids}&group_by=sector&aggregations=value&budget_period_start=#{firstDayOfFinYear}&budget_period_end=#{lastDayOfFinYear}&format=json")
	end
	
	def group_hashes arr, group_fields
			  arr.group_by {|hash| hash.values_at(*group_fields).join ":" }.values.map do |grouped|
			    grouped.inject do |merged, n|
			      merged.merge(n) do |key, v1, v2|
			        group_fields.include?(key) ? v1 : (v1.to_f + v2.to_f).to_s
		      	  end
		        end 
		      end
	end	

	def high_level_sector_listv2(apiUrl, listType)
		sectorValues  = JSON.parse(apiUrl)['response']['docs']
		# Load the high-level sector data from static contents
		sectorHierarchy = JSON.parse(File.read('data/sectorHierarchies.json'))
		#####
		## logic
		## get budget data, then check if they fall within date range
		## do a summation of the budget amount within date range
		## pick dac5 sector code and then get the underlying high level sector code
		## if the sector is present, add the new budget info to this sector
		## Else create a new ref to the high level sector code and add
		## budget value starting from 0
		## pick budget percentage for each dac5 sector code2
		## calculate the budget amount against that perentage and add it to
		## the high level related sector code
		finalData = []
		sectorValues.each do |element|
			tempTotalBudget = 0
			element['budget_period_start_iso_date'].each_with_index do |data, index|
				if(data.to_datetime >= settings.current_first_day_of_financial_year && element['budget_period_end_iso_date'][index].to_datetime <= settings.current_last_day_of_financial_year)
					tempTotalBudget = tempTotalBudget + element['budget_value'][index].to_f
				end
			end
			if element.has_key?('sector_code')
				element['sector_code'].each_with_index do |data, index|
					if !sectorHierarchy.find_index{|k,_| k['Code (L3)'].to_i == data.to_i}.nil?
						selectedHiLvlSectorData = sectorHierarchy.find{|k,_| k['Code (L3)'].to_i == data.to_i}
						if !finalData.find_index{|j,_| j['code'].to_i == selectedHiLvlSectorData['High Level Code (L1)'].to_i}.nil?
							if(element.has_key?('sector_percentage'))
								finalData[finalData.find_index{|j,_| j['code'].to_i == selectedHiLvlSectorData['High Level Code (L1)'].to_i}]['budget'] = finalData[finalData.find_index{|j,_| j['code'].to_i == selectedHiLvlSectorData['High Level Code (L1)'].to_i}]['budget'] + (tempTotalBudget * (element['sector_percentage'][index].to_f/100))
							else
								finalData[finalData.find_index{|j,_| j['code'].to_i == selectedHiLvlSectorData['High Level Code (L1)'].to_i}]['budget'] = finalData[finalData.find_index{|j,_| j['code'].to_i == selectedHiLvlSectorData['High Level Code (L1)'].to_i}]['budget'] + tempTotalBudget
							end
						else
							tempData = {}
							tempData['code'] = selectedHiLvlSectorData['High Level Code (L1)']
							tempData['name'] = selectedHiLvlSectorData['High Level Sector Description']
							if(element.has_key?('sector_percentage'))
								tempData['budget'] = tempTotalBudget * (element['sector_percentage'][index].to_f/100)
							else
								tempData['budget'] = tempTotalBudget
							end
							finalData.push(tempData)
						end
					end
				end
			end
		end
		if listType == "top_five_sectors"
	    	hiLevSecBudAggSorted = finalData.select{|s| s['code'].to_i != 22}.sort_by{ |k| k['budget'].to_f}.reverse
	    	hiLevSecBudAggSorted.first(10)	    	  
		else 
			#Sort the sectors by name
			sectorsData = finalData.sort_by{ |k| k['name']}
			#sectorsData = highLevelSectorBudgetAggregated.sort_by{ |k| k[:name]}
			#Find the total budget for all of the sectors
	  	 	totalBudget = Float(sectorsData.map { |s| s['budget'].to_f }.inject(:+))

	  	 	returnObject = {
				  'sectorsData' => sectorsData,
				  'totalBudget' => totalBudget				 				  
				}
	    end
	end

	def sector_parent_data_listv2(apiUrl, sectorHierarchy)
		#new api path: https://fcdo-direct-indexing.iati.cloud/search/activity?q=reporting_org_ref:(GB-GOV-1 GB-1) AND budget_period_start_iso_date:[2021-04-01T00:00:00Z TO *] AND budget_period_end_iso_date:[* TO 2022-03-31T00:00:00Z]&rows=10000&fl=sector_code,sector_percentage,budget_value_gbp_sum
		sectorValues  = JSON.parse(apiUrl)['response']['docs']
		# Load the high-level sector data from static contents
		finalData = []
		sectorValues.each do |element|
			tempTotalBudget = 0
			element['budget_period_start_iso_date'].each_with_index do |data, index|
				if(data.to_datetime >= settings.current_first_day_of_financial_year && element['budget_period_end_iso_date'][index].to_datetime <= settings.current_last_day_of_financial_year)
					tempTotalBudget = tempTotalBudget + element['budget_value'][index].to_f
				end
			end
			if element.has_key?('sector_code')
				element['sector_code'].each_with_index do |data, index|
					if !sectorHierarchy.find_index{|k,_| k['Code (L3)'].to_i == data.to_i}.nil?
						selectedHiLvlSectorData = sectorHierarchy.find{|k,_| k['Code (L3)'].to_i == data.to_i}
						if !finalData.find_index{|j,_| j['code'].to_i == selectedHiLvlSectorData['Category (L2)'].to_i}.nil?
							if(element.has_key?('sector_percentage'))
								finalData[finalData.find_index{|j,_| j['code'].to_i == selectedHiLvlSectorData['Category (L2)'].to_i}]['budget'] = finalData[finalData.find_index{|j,_| j['code'].to_i == selectedHiLvlSectorData['Category (L2)'].to_i}]['budget'] + (tempTotalBudget * (element['sector_percentage'][index].to_f/100))
							else
								finalData[finalData.find_index{|j,_| j['code'].to_i == selectedHiLvlSectorData['Category (L2)'].to_i}]['budget'] = finalData[finalData.find_index{|j,_| j['code'].to_i == selectedHiLvlSectorData['Category (L2)'].to_i}]['budget'] + tempTotalBudget
							end
						else
							tempData = {}
							tempData['code'] = selectedHiLvlSectorData['Category (L2)']
							tempData['name'] = selectedHiLvlSectorData['Category Name']
							tempData['parentCode'] = selectedHiLvlSectorData['High Level Code (L1)']
							if(element.has_key?('sector_percentage'))
								tempData['budget'] = tempTotalBudget * (element['sector_percentage'][index].to_f/100)
							else
								tempData['budget'] = tempTotalBudget
							end
							finalData.push(tempData)
						end
					end
				end
			end
		end
		#Sort the sectors by name
		sectorsData = finalData.sort_by{ |k| k['name']}
		#sectorsData = highLevelSectorBudgetAggregated.sort_by{ |k| k[:name]}
		#Find the total budget for all of the sectors
		totalBudget = Float(sectorsData.map { |s| s['budget'].to_f }.inject(:+))
		highLevelSectorInfo = {}
		highLevelSectorInfo['highLevelSectorCode'] = sectorHierarchy.first['High Level Code (L1)']
		highLevelSectorInfo['highLevelSectorDescription'] = sectorHierarchy.first['High Level Sector Description']

		returnObject = {
			'sectorData' => sectorsData,
			'totalBudget' => totalBudget,
			'sectorHierarchyPath' => highLevelSectorInfo		 				  
		}
	end

	def sector_parent_data_dac5(apiUrl, sectorHierarchy)
		#new api path: https://fcdo-direct-indexing.iati.cloud/search/activity?q=reporting_org_ref:(GB-GOV-1 GB-1) AND budget_period_start_iso_date:[2021-04-01T00:00:00Z TO *] AND budget_period_end_iso_date:[* TO 2022-03-31T00:00:00Z]&rows=10000&fl=sector_code,sector_percentage,budget_value_gbp_sum
		sectorValues  = JSON.parse(apiUrl)['response']['docs']
		# Load the high-level sector data from static contents
		finalData = []
		sectorValues.each do |element|
			tempTotalBudget = 0
			element['budget_period_start_iso_date'].each_with_index do |data, index|
				if(data.to_datetime >= settings.current_first_day_of_financial_year && element['budget_period_end_iso_date'][index].to_datetime <= settings.current_last_day_of_financial_year)
					tempTotalBudget = tempTotalBudget + element['budget_value'][index].to_f
				end
			end
			if element.has_key?('sector_code')
				element['sector_code'].each_with_index do |data, index|
					if !sectorHierarchy.find_index{|k,_| k['Code (L3)'].to_i == data.to_i}.nil?
						selectedHiLvlSectorData = sectorHierarchy.find{|k,_| k['Code (L3)'].to_i == data.to_i}
						if !finalData.find_index{|j,_| j['code'].to_i == selectedHiLvlSectorData['Code (L3)'].to_i}.nil?
							if(element.has_key?('sector_percentage'))
								finalData[finalData.find_index{|j,_| j['code'].to_i == selectedHiLvlSectorData['Code (L3)'].to_i}]['budget'] = finalData[finalData.find_index{|j,_| j['code'].to_i == selectedHiLvlSectorData['Code (L3)'].to_i}]['budget'] + (tempTotalBudget * (element['sector_percentage'][index].to_f/100))
							else
								finalData[finalData.find_index{|j,_| j['code'].to_i == selectedHiLvlSectorData['Code (L3)'].to_i}]['budget'] = finalData[finalData.find_index{|j,_| j['code'].to_i == selectedHiLvlSectorData['Code (L3)'].to_i}]['budget'] + tempTotalBudget
							end
						else
							tempData = {}
							tempData['code'] = selectedHiLvlSectorData['Code (L3)']
							tempData['name'] = selectedHiLvlSectorData['Name']
							tempData['parentCode'] = selectedHiLvlSectorData['Category (L2)']
							if(element.has_key?('sector_percentage'))
								tempData['budget'] = tempTotalBudget * (element['sector_percentage'][index].to_f/100)
							else
								tempData['budget'] = tempTotalBudget
							end
							finalData.push(tempData)
						end
					end
				end
			end
		end
		#Sort the sectors by name
		sectorsData = finalData.sort_by{ |k| k['name']}
		#sectorsData = highLevelSectorBudgetAggregated.sort_by{ |k| k[:name]}
		#Find the total budget for all of the sectors
		totalBudget = Float(sectorsData.map { |s| s['budget'].to_f }.inject(:+))
		highLevelSectorInfo = {}
		highLevelSectorInfo['highLevelSectorCode'] = sectorHierarchy.first['High Level Code (L1)']
		highLevelSectorInfo['highLevelSectorDescription'] = sectorHierarchy.first['High Level Sector Description']
		highLevelSectorInfo['categoryCode'] = sectorHierarchy.first['Category (L2)']
		highLevelSectorInfo['categoryDescription'] = sectorHierarchy.first['Category Name']

		returnObject = {
			'sectorData' => sectorsData,
			'totalBudget' => totalBudget,
			'sectorHierarchyPath' => highLevelSectorInfo		 				  
		}
	end

	def map_sector_data()
		sectorValuesJSON = RestClient.get  api_simple_log('https://devtracker.fcdo.gov.uk/api/' + "budgets/aggregations/?reporting_organisation_identifier=#{settings.goverment_department_ids}&group_by=sector&aggregations=value&budget_period_start=#{settings.current_first_day_of_financial_year}&budget_period_end=#{settings.current_last_day_of_financial_year}&format=json")
		sectorValues  = JSON.parse(sectorValuesJSON)
		sectorHierarchy = JSON.parse(File.read('data/sectorHierarchies.json'))
		sectorValues['results'].each do |elem|
			begin
				selectedData = sectorHierarchy.find {|item| item['Code (L3)'].to_s == elem["sector"]["code"]}
				td = selectedData["Code (L3)"]
			rescue
				tempData = {}
				tempData["Code (L3)"] = elem['sector']['code']
				tempData["High Level Code (L1)"] = 0
				tempData["High Level Sector Description"] = "Uncategorised"
				tempData["Name"] = elem['sector']['name']
				tempData["Description"] = 'Not yet mapped'
				tempData["Category (L2)"] = 0
				tempData["Category Name"] = "Not yet mapped"
				tempData["Category Description"] = "Not yet mapped"
				sectorHierarchy.push(tempData)
			end
		end
		sectorHierarchy
	end

	# Return all of the DAC Sector codes associated with the parent sector code	- can be used for 3 digit (category) or 5 digit sector codes
	def sector_parent_data_list(apiUrl, pageType, code, description, parentCodeType, parentDescriptionType, urlHighLevelSectorCode, urlCategoryCode)
		sectorValuesJSON = RestClient.get  api_simple_log(apiUrl + "budgets/aggregations/?reporting_organisation_identifier=#{settings.goverment_department_ids}&group_by=sector&aggregations=value&budget_period_start=#{settings.current_first_day_of_financial_year}&budget_period_end=#{settings.current_last_day_of_financial_year}&format=json")
 		sectorValues  = JSON.parse(sectorValuesJSON)
  		sectorValues  = sectorValues['results']
  		#sectorHierarchy = JSON.parse(File.read('data/sectorHierarchies.json'))
		sectorHierarchy = map_sector_data()
		# Create a data structure that holds: budget, child code, child description & parent code
		budgetData = []
		sectorValues.each do |elem|
			begin
			selectedData = sectorHierarchy.find {|item| item['Code (L3)'].to_s == elem["sector"]["code"]}
			tempData = {}
			tempData[:code] = selectedData[code]
			tempData[:name] = selectedData[description]
			tempData[:parentCode] = selectedData[parentCodeType]
			tempData[:budget] = elem["value"]
			budgetData.push(tempData)
			rescue
				tempData = {}
				tempData[:code] = urlCategoryCode
				tempData[:parentCode] = 0
				tempData[:name] = 'Uncategorised'
				tempData[:budget] = elem["value"]
				budgetData.push(tempData)
			end
		end
        # budgetData = sectorValues.map do |elem|
		# 	{  
		# 		:code 		 => sectorHierarchy.find do |source|
		# 							source["Code (L3)"].to_s == elem["sector"]["code"] 
		# 						end[code],   
		# 		:name 		 => sectorHierarchy.find do |source|
		# 							source["Code (L3)"].to_s == elem["sector"]["code"]
		# 						end[description], 
		# 		:parentCode   => sectorHierarchy.find do |source|
		# 							source["Code (L3)"].to_s == elem["sector"]["code"]
		# 						end[parentCodeType],                      			
		# 		:budget       => elem["value"]      			                         			           			                          
		# 	} 
	    #  end

	     #TODO - test the input to see that there is no bad data comming in
		if pageType == "category"
	     	inputCode = urlHighLevelSectorCode
	     	sectorHierarchyPath = {	     
	     			:highLevelSectorCode => inputCode,			
	     			:highLevelSectorDescription => sectorHierarchy.find { |i| i[parentCodeType].to_s == inputCode }[parentDescriptionType]
	     	}	     	
	    else	
	     	inputCode = urlCategoryCode
	     	sectorHierarchyPath = {	     			
	     			:highLevelSectorCode => urlHighLevelSectorCode,	
	     			:highLevelSectorDescription => sectorHierarchy.find { |i| i[parentCodeType].to_s == inputCode}["High Level Sector Description"],	
	     			:categoryCode => inputCode,	 
	     			:categoryDescription => sectorHierarchy.find { |i| i[parentCodeType].to_s == inputCode }[parentDescriptionType]	     		
	     	}
		end

		 #Return the parent's description
	  	 parentDescription  = sectorHierarchy.find { |i| i[parentCodeType].to_s == inputCode }[parentDescriptionType]

	     #Remove all items from the data structure aren't related to the selected parent code 
	     selectedCodes = budgetData.delete_if { |h| h[:parentCode].to_s != inputCode }

	     if pageType == "category"
	     	#Aggregate all of the budget values for each child code & sort the list by name
	  	 	selectedCodesBudgetAggregated = group_hashes  selectedCodes, [:code,:name,:parentCode]
			selectedCodesBudgetAggregatedSorted = selectedCodesBudgetAggregated.sort_by{ |k| k[:name]}
		 else
		 	#DAC 5 digit sector code budgets are pre-aggregated in the API 
		 	selectedCodesBudgetAggregatedSorted = selectedCodes.sort_by{ |k| k[:name]}	
		 end 		     	
	 
	  	 #Calculate the sum of all of the budgets in the data structure 
	  	 totalBudget = Float(selectedCodesBudgetAggregatedSorted.map { |s| s[:budget].to_f }.inject(:+))
       	 
	   	 returnObject = {
				  :sectorData  => selectedCodesBudgetAggregatedSorted,
				  :totalBudget => totalBudget,
				  :sectorHierarchyPath => sectorHierarchyPath  	  				  
    			}	  			
	 end

	 def prepare_location_country_region_data(activityStatus, sectorCode)
	 	data = {}
	 	locationCountryFilters = JSON.parse(RestClient.get  api_simple_log(settings.oipa_api_url + "activities/aggregations/?hierarchy=1&format=json&reporting_organisation_identifier=#{settings.goverment_department_ids}&group_by=recipient_country&aggregations=count&related_activity_sector=#{sectorCode}&activity_status=#{activityStatus}"))
  		locationCountryFilters = locationCountryFilters['results'].sort_by {|key| key["recipient_country"]["name"]}
  		locationRegionFilters = JSON.parse(RestClient.get  api_simple_log(settings.oipa_api_url + "activities/aggregations/?hierarchy=1&format=json&reporting_organisation_identifier=#{settings.goverment_department_ids}&group_by=recipient_region&aggregations=count&related_activity_sector=#{sectorCode}&activity_status=#{activityStatus}"))
  		locationRegionFilters = locationRegionFilters['results'].sort_by {|key| key["recipient_region"]["name"]}
  		data['locationCountryFilters'] = locationCountryFilters
  		data['locationRegionFilters'] = locationRegionFilters
  		data
	 end

	 def get_hash_data_with_high_level_sector_name(hashData)
		 #highLevelSector = JSON.parse(File.read('data/sectorHierarchies.json'))
		 highLevelSector = map_sector_data()
	 	hashData.each do |result|
	 		result["higherLevelSectorName"] = highLevelSector.select{|k| k["Code (L3)"].to_s==result["sectorId"]}.map{|x| x["High Level Sector Description"]}[0]
	 	end

	 	return hashData
	 end
end
