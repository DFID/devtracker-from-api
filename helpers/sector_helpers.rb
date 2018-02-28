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
		sectorValuesJSON = RestClient.get settings.oipa_api_url + "budgets/aggregations/?reporting_organisation=GB-GOV-1&group_by=sector&aggregations=value&budget_period_start=#{firstDayOfFinYear}&budget_period_end=#{lastDayOfFinYear}&format=json"
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
  		highLevelSector = JSON.parse(File.read('data/sectorHierarchies.json'))

        #Create a data structure to map each DAC 5 sector code to a high level sector code          
        highLevelSectorBudget = sectorValues.map do |elem| 
	       {  
	       	   :code 		 => highLevelSector.find do |source|
                         			source["Code (L3)"].to_s == elem["sector"]["code"]
                      			end[codeType], # "High Level Code (L1)"  High Level Sector Description"  
			   :name 		 => highLevelSector.find do |source|
                         			source["Code (L3)"].to_s == elem["sector"]["code"]
                      			end[sectorDescription], #"High Level Sector Description"
               #oipa v2.2
               #:budget       => elem["budget"]
               #oipa v3.1
               :budget       => elem["value"].to_i                       			           			                          
	       } 
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


	# Return all of the DAC Sector codes associated with the parent sector code	- can be used for 3 digit (category) or 5 digit sector codes
	def sector_parent_data_list(apiUrl, pageType, code, description, parentCodeType, parentDescriptionType, urlHighLevelSectorCode, urlCategoryCode)


		sectorValuesJSON = RestClient.get apiUrl + "budgets/aggregations/?reporting_organisation=GB-GOV-1&group_by=sector&aggregations=value&budget_period_start=#{settings.current_first_day_of_financial_year}&budget_period_end=#{settings.current_last_day_of_financial_year}&format=json"
 		sectorValues  = JSON.parse(sectorValuesJSON)
  		sectorValues  = sectorValues['results']
  		sectorHierarchy = JSON.parse(File.read('data/sectorHierarchies.json'))
        
        # Create a data structure that holds: budget, child code, child description & parent code
        budgetData = sectorValues.map do |elem| 
	       {  
	       	   :code 		 => sectorHierarchy.find do |source|
                         			source["Code (L3)"].to_s == elem["sector"]["code"] 
                      			end[code],   
			   :name 		 => sectorHierarchy.find do |source|
                         			source["Code (L3)"].to_s == elem["sector"]["code"]
                      			end[description], 
      		   :parentCode   => sectorHierarchy.find do |source|
                         			source["Code (L3)"].to_s == elem["sector"]["code"]
                      			end[parentCodeType],                      			
               :budget       => elem["value"]      			                         			           			                          
	       } 
	     end

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

	def get_sector_projects(n)
		oipa_project_list = RestClient.get settings.oipa_api_url + "activities/?hierarchy=1&format=json&reporting_organisation=GB-GOV-1&page_size=10&fields=descriptions,activity_status,iati_identifier,url,title,reporting_organisations,activity_plus_child_aggregation,aggregations&activity_status=2&ordering=-activity_plus_child_budget_value&related_activity_sector=#{n}"
		projects= JSON.parse(oipa_project_list)
		results = {}
		sectorValuesJSON = RestClient.get settings.oipa_api_url + "activities/aggregations/?format=json&group_by=sector&aggregations=count&reporting_organisation=GB-GOV-1&related_activity_sector=#{n}&activity_status=2"
		results['highLevelSectorList'] = high_level_sector_list_filter(sectorValuesJSON)
		#results['LocationCountries'] = JSON.parse(RestClient.get settings.oipa_api_url + "activities/?hierarchy=1&format=json&reporting_organisation=GB-GOV-1&page_size=10&fields=descriptions,activity_status,iati_identifier,url,title,reporting_organisations,activity_plus_child_aggregation&activity_status=1,2,3,4,5&ordering=-activity_plus_child_budget_value&related_activity_sector=#{n}")
		results['LocationCountries'] = JSON.parse(RestClient.get settings.oipa_api_url + "activities/aggregations/?hierarchy=1&format=json&reporting_organisation=GB-GOV-1&group_by=recipient_country&aggregations=count&related_activity_sector=#{n}&activity_status=2")
		results['LocationRegions'] = JSON.parse(RestClient.get settings.oipa_api_url + "activities/aggregations/?hierarchy=1&format=json&reporting_organisation=GB-GOV-1&group_by=recipient_region&aggregations=count&related_activity_sector=#{n}&activity_status=2")
		results['project_budget_higher_bound'] = 0
		results['actualStartDate'] = '1990-01-01T00:00:00' 
		results['plannedEndDate'] = '2000-01-01T00:00:00'
		unless projects['results'][0].nil?
			results['project_budget_higher_bound'] = projects['results'][0]['aggregations']['activity_children']['budget_value']
		end
		begin
			results['actualStartDate'] = RestClient.get settings.oipa_api_url + "activities/?format=json&page_size=1&fields=activity_dates&reporting_organisation=GB-GOV-1&hierarchy=1&related_activity_sector=#{n}&ordering=actual_start_date&start_date_gte=1900-01-02&activity_status=2"
			results['actualStartDate'] = JSON.parse(results['actualStartDate'])
			tempStartDate = results['actualStartDate']['results'][0]['activity_dates'].select{|activityDate| activityDate['type']['code'] == '2'}.first
			if (tempStartDate.nil?)
			tempStartDate = results['actualStartDate']['results'][0]['activity_dates'].select{|activityDate| activityDate['type']['code'] == '1'}.first
			end
	      	results['actualStartDate'] = tempStartDate
	      	results['actualStartDate'] = results['actualStartDate']['iso_date']
		rescue
			results['actualStartDate'] = '1990-01-01T00:00:00'
		end

		#unless results['actualStartDate']['results'][0].nil? 
		#	results['actualStartDate'] = results['actualStartDate']['results'][0]['activity_dates'][1]['iso_date']
		#end
		begin
			results['plannedEndDate'] = RestClient.get settings.oipa_api_url + "activities/?format=json&page_size=1&fields=activity_dates&reporting_organisation=GB-GOV-1&hierarchy=1&related_activity_sector=#{n}&ordering=-planned_end_date&end_date_isnull=False&activity_status=2"
			results['plannedEndDate'] = JSON.parse(results['plannedEndDate'])
			results['plannedEndDate'] = results['plannedEndDate']['results'][0]['activity_dates'].select{|activityDate| activityDate['type']['code'] == '3'}.first
			results['plannedEndDate'] = results['plannedEndDate']['iso_date']
		rescue
			results['plannedEndDate'] = '2000-01-01T00:00:00'
		end

		#unless results['plannedEndDate']['results'][0].nil?
		#	if !results['plannedEndDate']['results'][0]['activity_dates'][2].nil?
		#		results['plannedEndDate'] = results['plannedEndDate']['results'][0]['activity_dates'][2]['iso_date']
		#	else
				#This is an issue. For now it's a temporary remedy used to avoid a ruby error but, this needs to be fixed once zz helps out with the api call to return the actual/planned end date.
		#		results['plannedEndDate'] = '2050-12-31T00:00:00'
		#	end
		#end
		results['projects'] = projects
		#This code is created for generating the left hand side document type filter list
		oipa_document_type_list = RestClient.get settings.oipa_api_url + "activities/aggregations/?format=json&group_by=document_link_category&aggregations=count&reporting_organisation=GB-GOV-1&related_activity_sector=#{n}&activity_status=2"
		document_type_list = JSON.parse(oipa_document_type_list)
		results['document_types'] = document_type_list['results']

		#Implementing org type filters
		participatingOrgInfo = JSON.parse(File.read('data/participatingOrgList.json'))
		oipa_implementingOrg_type_list = RestClient.get settings.oipa_api_url + "activities/aggregations/?format=json&group_by=participating_organisation&aggregations=count&reporting_organisation=GB-GOV-1&hierarchy=1&related_activity_sector=#{n}&activity_status=2"
		implementingOrg_type_list = JSON.parse(oipa_implementingOrg_type_list)
		results['implementingOrg_types'] = implementingOrg_type_list['results']
		results['implementingOrg_types'].each do |implementingOrgs|
			if implementingOrgs['participating_organisation'].length < 1
				tempImplmentingOrgData = participatingOrgInfo.select{|implementingOrg| implementingOrg['Code'].to_s == implementingOrgs['participating_organisation_ref'].to_s}.first
		   		if tempImplmentingOrgData.nil?
		   			implementingOrgs['participating_organisation'] = 'na'
		   			implementingOrgs['participating_organisation_ref'] = 'na'
		   		else
		   			implementingOrgs['participating_organisation'] = tempImplmentingOrgData['Name']
		   		end
			end
		end
		results['LocationCountries'] = results['LocationCountries']['results']
		results['LocationCountries'] = results['LocationCountries'].sort_by {|key| key["recipient_country"]["name"]}
		results['LocationRegions'] = results['LocationRegions']['results']
		results['LocationRegions'] = results['LocationRegions'].sort_by {|key| key["recipient_region"]["name"]}
		results['highLevelSectorList'] = results['highLevelSectorList'].sort_by {|key| key}
    	results['document_types'] = results['document_types'].sort_by {|key| key["document_link_category"]["name"]}
    	results['implementingOrg_types'] = results['implementingOrg_types'].sort_by {|key| key["participating_organisation"]}.uniq{|key| key["participating_organisation_ref"]}
		return results
	end
end
