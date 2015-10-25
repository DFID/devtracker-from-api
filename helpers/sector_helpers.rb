module SectorHelpers

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

		#sectorValuesJSON = RestClient.get apiUrl + "activities/aggregations?reporting_organisation=GB-1&group_by=sector&aggregations=budget&format=json"
  		sectorValues  = JSON.parse(apiUrl)
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
               :budget       => elem["budget"]      			                         			           			                          
	       } 
	     end

	    #Aggregate the budget for each high level sector code (i.e. remove duplicate sector codes from the data structure and aggregate the budgets)
	   	highLevelSectorBudgetAggregated = group_hashes  highLevelSectorBudget, [:code,:name]
	    
	    if listType == "top_five_sectors"
	    	hiLevSecBudAggSorted = highLevelSectorBudgetAggregated.sort_by{ |k| k[:budget].to_f}.reverse
	    	hiLevSecBudAggSorted.first(5)	    	  
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

		sectorValuesJSON = RestClient.get apiUrl + "activities/aggregations?reporting_organisation=GB-1&group_by=sector&aggregations=budget&format=json"
  		sectorValues  = JSON.parse(sectorValuesJSON)
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
               :budget       => elem["budget"]      			                         			           			                          
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
end
