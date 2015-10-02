module SectorHelpers


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

		sectorValuesJSON = RestClient.get apiUrl + "activities/aggregations?reporting_organisation=GB-1&group_by=sector&aggregations=budget&order_by=-budget&format=json"
  		sectorValues  = JSON.parse(sectorValuesJSON)
  		highLevelSector = JSON.parse(File.read('data/sector_hierarchies.json'))
        
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
	    hiLevSecBudAggregated = group_hashes  highLevelSectorBudget, [:code,:name]
	    
	    if listType == "top_five_sectors"
	    	hiLevSecBudAggSorted = hiLevSecBudAggregated.sort_by{ |k| k[:budget].to_f}.reverse
	    	hiLevSecBudAggSorted.first(5)	    	  
		else 
			hiLevSecBudNameSorted = hiLevSecBudAggregated.sort_by{ |k| k[:name]}
	    end 

	end

	# Return all of the three digit DAC Sector codes (categories) associated with the input high level sector code
	def category_list(apiUrl, listType, categoryCode, categoryDescription, highLevelCode)

		sectorValuesJSON = RestClient.get apiUrl + "activities/aggregations?reporting_organisation=GB-1&group_by=sector&aggregations=budget&order_by=-budget&format=json"
  		sectorValues  = JSON.parse(sectorValuesJSON)
  		highLevelSector = JSON.parse(File.read('data/sector_hierarchies.json'))
        
        # Create a data structure that holds budget against category code and 
        categoryBudget = sectorValues.map do |elem| 
	       {  
	       	   :code 		 => highLevelSector.find do |source|
                         			source["Code (L3)"].to_s == elem["sector"]["code"] 
                      			end[categoryCode],   
			   :name 		 => highLevelSector.find do |source|
                         			source["Code (L3)"].to_s == elem["sector"]["code"]
                      			end[categoryDescription], 
      		   :highLevelCode => highLevelSector.find do |source|
                         			source["Code (L3)"].to_s == elem["sector"]["code"]
                      			end[highLevelCode],                      			
               :budget       => elem["budget"]      			                         			           			                          
	       } 
	     end

	     #TODO - test the input to see that there is no bad data comming in
	     

	     selectedCategories = categoryBudget.delete_if { |h| h[:highLevelCode].to_s != "2" }

	  	 selectedCategorysBudgetAggregated = group_hashes  selectedCategories, [:code,:name,:highLevelCode]
	  	 
	  	 highLevelSectorBudget = Float(selectedCategorysBudgetAggregated.map { |s| s[:budget].to_f }.inject(:+))

	   	 highLevelSectorDescription = highLevelSector.find { |i| i["High Level Code (L1)"].to_s == "2" }["High Level Sector Description"]

	   	 returnObject = {
				  :categoriesData => selectedCategorysBudgetAggregated,
				  :totalBudget => highLevelSectorBudget,
				  :highLevelDesc => highLevelSectorDescription				  
				}	   	 	

	 end
	

	




	def sector_categories_structure(highLevelSectorCode)

		sectors = @cms_db['sector-hierarchies'].aggregate([{
			"$match" => {
				"highLevelCode" => highLevelSectorCode
			}			
		},{ 
			"$group" => { 
				"_id"  => "$categoryCode",
				"name" => {
					"$first" => "$categoryName"
				}, 
				"sectorCodes" => {
					"$addToSet" => "$sectorCode"
				} 
			} 
		}]).map { |l| {
			:code   => l['_id'],
			:name   => l['name'],
			:budget => calculate_total_sector_level_budget(l['sectorCodes'])
		}}

		calculate_hierarchy_structure(sectors)
	end

	def sectors_structure(categoryCode)		
 		sectors = @cms_db['sector-hierarchies'].find({
			"categoryCode" => categoryCode
		}).map { |l| {
			:code   => l['sectorCode'],
			:name   => l['sectorName'],
			:budget => calculate_total_sector_level_budget([ l['sectorCode'] ])
		}}

		calculate_hierarchy_structure(sectors)
	end

	def retrieve_project_name(projectIatiId)
		result = @cms_db['projects'].find({
			'iatiId' => projectIatiId
		})
		((result.first || { 'title' => projectIatiId })['title'])
	end

	def calculate_hierarchy_structure(sectors)
		totalSectorsBudget = Float(sectors.map { |s| s[:budget] }.inject(:+))
		maxBudget = Float(sectors.max_by { |s| s[:budget] }[:budget])

		sectors.sort_by { |s| s[:name] }.map { |s| s.merge({
			:percentage => s[:budget] / totalSectorsBudget * 100.0,
			:cellWidth	=> s[:budget] / maxBudget * 60.0
		})}.select { |s| s[:percentage] >= 0.01 }
	end		

	def calculate_total_sector_level_budget(sectorCodes)
		result = @cms_db['project-sector-budgets'].aggregate([
			{
				"$match" => {
					"sectorCode" => {
						"$in" => sectorCodes
					},
					"date" => {
						"$gte" => "#{financial_year}-04-01",
						"$lte" => "#{financial_year + 1}-03-31"
					}
				}
			}, {
				"$group" => {
					"_id" => nil, 
					"total" => {
						"$sum" => "$sectorBudget"}
				}
			}
		])
		(result.first || { 'total' => 0 })['total']
	end

	def retrieve_high_level_sector_names(projectIatiId)
		sectorCodes = @cms_db['project-sector-budgets'].find({
			"projectIatiId" => projectIatiId
		}).map { |s| s['sectorCode'] }.to_a

		sectorNames = @cms_db['sector-hierarchies'].find({
			"sectorCode" => {"$in" => sectorCodes}
		}).map { |s| s['highLevelName'] }.to_a.uniq.join('#')
	end
end
