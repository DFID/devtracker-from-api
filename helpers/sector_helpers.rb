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


	def high_level_sector_list(apiUrl, listType, codeType, sectorDescription )

  		sectorValues  = JSON.parse(apiUrl)
  		sectorValues  = sectorValues['results'] 
		#highLevelSector = JSON.parse(File.read('data/sectorHierarchies.json'))
		highLevelSector = map_sector_data()
		#Create a data structure to map each DAC 5 sector code to a high level sector code
		highLevelSectorBudget = []
		sectorValues.each do |elem|
			begin
			selectedData = highLevelSector.find {|item| item['Code (L3)'].to_s == elem["sector"]["code"]}
			tempData = {}
			tempData[:code] = selectedData[codeType]
			tempData[:name] = selectedData[sectorDescription]
			tempData[:budget] = elem["value"].to_i
			highLevelSectorBudget.push(tempData)
			rescue
				puts elem["sector"]["code"]
				tempData = {}
				tempData[:code] = 0
				tempData[:name] = 'Uncategorised'
				tempData[:budget] = elem["value"].to_i
				highLevelSectorBudget.push(tempData)
			end
		end          
        
	    #Aggregate the budget for each high level sector code (i.e. remove duplicate sector codes from the data structure and aggregate the budgets)
	   	highLevelSectorBudgetAggregated = group_hashes  highLevelSectorBudget, [:code,:name]
  	
  		#remove unallocated sector as we don't want to show that
  		highLevelSectorBudgetAggregatedNoUnalloc = highLevelSectorBudgetAggregated.reject{|h| h[:name] == "Unallocated"}
	    
	    if listType == "top_five_sectors"
	    	hiLevSecBudAggSorted = highLevelSectorBudgetAggregatedNoUnalloc.sort_by{ |k| k[:budget].to_f}.reverse
	    	hiLevSecBudAggSorted.first(10)	    	  
		else 
			#Sort the sectors by name
			sectorsData = highLevelSectorBudgetAggregated.sort_by{ |k| k[:name]}
			#Find the total budget for all of the sectors
	  	 	totalBudget = Float(sectorsData.map { |s| s[:budget].to_f }.inject(:+))

	  	 	returnObject = {
				  :sectorsData => sectorsData,
				  :totalBudget => totalBudget				 				  
				}
	    end 

	end

	def map_sector_data()
		sectorValuesJSON = RestClient.get  api_simple_log(settings.oipa_api_url + "budgets/aggregations/?reporting_organisation_identifier=#{settings.goverment_department_ids}&group_by=sector&aggregations=value&budget_period_start=#{settings.current_first_day_of_financial_year}&budget_period_end=#{settings.current_last_day_of_financial_year}&format=json")
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
				puts elem["sector"]["code"]
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
			puts urlHighLevelSectorCode
			puts parentCodeType
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
