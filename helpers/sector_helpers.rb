module SectorHelpers


	def high_level_sectors_structure_legacy
=begin
		sectors = @cms_db['sector-hierarchies'].aggregate([{ 
				"$group" => { 
				"_id"  => "$highLevelCode",
				"name" => {
					"$first" => "$highLevelName"
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
=end		
	end

	def group_hashes arr, group_fields
			  arr(0).group_by {|hash| hash.values_at(*group_fields).join ":" }.values.map do |grouped|
			    grouped.inject do |merged, n|
			      merged.merge(n) do |key, v1, v2|
			        group_fields.include?(key) ? v1 : (v1.to_f + v2.to_f).to_s
		      	  end
		        end 
		      end
	end	


	def sector_budgets

		# TODO - Need to change the hard coded Budget period to variable
		oipaSectorValuesJSON = RestClient.get "http://dfid-oipa.zz-clients.net/api/activities/aggregations?reporting_organisation=GB-1&group_by=sector&aggregations=budget&budget_period_start=2015-04-01&budget_period_end=2016-03-31&order_by=-budget&format=json"
		sectorValuesJSON=JSON.parse(oipaSectorValuesJSON)
		highLevelSector = JSON.parse(File.read('data/sector_hierarchies.json'))

=begin
		# Create an hash of DAC5 sector budgets from the API call input (i.e. flatten the data so that the budget is at the same level as the code and name attributes)
		dac5SectorBudget = sectorValuesJSON.map do |elem| 
							{
								"Code (L3)"    => elem["sector"]["code"],
						        :budget        => elem["budget"]
						    }    
		end	
=end

	
		# Test code to show that value of contained in the high level sectors has been aggregated correctly

		sectorBudgets = []

		# Create an array of sector budgets from the API call input (i.e. flatten the data so that the budget is at the same level as the code and name attributes)
		sectorValuesJSON.each do |elem|
			p = [ elem["sector"]["code"], elem["budget"]]
			sectorBudgets << p
		end			

		highLevelSectorBudgets = []

		sectorBudgets.each do |elem|	
			getHighLevelSector = highLevelSector.select {|h| h["Code (L3)"].to_s == elem[0]}.first
			if !getHighLevelSector.nil?  then
				p = ["High Level Code", getHighLevelSector["High Level Code (L1)"], "High Level Sector" ,getHighLevelSector["High Level Sector Description"], "Budget", elem[1]]
		    	highLevelSectorBudgets << p  
			end
		end			

		highLevelSectorBudgets
		
=begin  Create a hash table from the multi dimensional array to pass into the group by function
		highLevelSectorBudgetsHash = Hash.new
										highLevelSectorBudgets.each_index  do { |e|

										   # year = e[0]
										   # month = e[1]
										    entry = e[0]

										    # Add to years array
										   # years[year] ||= Hash.new
										   # years[year][month] ||= Array.new
										    highLevelSectorBudgetsHash["test"] << entry
										} end

		highLevelSectorBudgetsHash
=end

      	#	group_hashes highLevelSectorBudgetsHash, ["order", "idx", "account"]

	end

	def high_level_sector_list
		
	#	highLevelSector = JSON.parse(File.read('data/sector_hierarchies.json'))
		
		sectorValuesJSON = RestClient.get "http://dfid-oipa.zz-clients.net/api/activities/aggregations?reporting_organisation=GB-1&group_by=sector&aggregations=budget&order_by=-budget&format=json"
  		sectorValues  = JSON.parse(sectorValuesJSON)

  		highLevelSector = JSON.parse(File.read('data/test_sh.json'))
  	#	sectorValues  = JSON.parse(File.read('data/test_budget.json'))


		highLevelSector.map do |elem| 
	       {  
	       	  :code          => elem["High Level Code (L1)"],
	          :name          => elem["High Level Sector Description"],
			  :budget 		  => sectorValues.select do |source|
                         			source["sector"]["code"] == elem["Code (L3)"].to_s 
                      			end.map{|elem|elem["budget"]}.inject(:+)	                            

	       } 
		end

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
