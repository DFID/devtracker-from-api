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

	def high_level_sector_list

		sectorValuesJSON = RestClient.get "http://dfid-oipa.zz-clients.net/api/activities/aggregations?reporting_organisation=GB-1&group_by=sector&aggregations=budget&order_by=-budget&format=json"
  		sectorValues  = JSON.parse(sectorValuesJSON)
  		highLevelSector = JSON.parse(File.read('data/sector_hierarchies.json'))

#		highLevelSector.map do |elem| 
#	       {  
#	       	  :code          => elem["High Level Code (L1)"],
#	          :name          => elem["High Level Sector Description"],
#			  :budget 		  => sectorValues.select do |source|
#                        			source["sector"]["code"] == elem["Code (L3)"].to_s 
#                      			end.map{|elem|elem["budget"]}.inject(:+)	                            
#	       } 
#		end

		 highLevelSectorBudget = sectorValues.map do |elem| 
	       {  
	       	   :code 		 => highLevelSector.find do |source|
                         			source["Code (L3)"].to_s == elem["sector"]["code"]
                      			end["High Level Code (L1)"],     
			   :name 		 => highLevelSector.find do |source|
                         			source["Code (L3)"].to_s == elem["sector"]["code"]
                      			end["High Level Sector Description"],
               :budget       => elem["budget"]      			                         			           			                          
	       } 
	     end
   		
	    group_hashes  highLevelSectorBudget, [:code,:name]
  	  
	end

	

	def test_code
   
	input = 	[{:code=>22, :name=>"Unallocated", :budget=>37345252476.0}, 
			{:code=>2, :name=>"Health", :budget=>31952581143.0}, 
			{:code=>4, :name=>"Government and Civil Society", :budget=>30889047493.0}, 
			{:code=>1, :name=>"Education", :budget=>29135078655.0}, 
			{:code=>5, :name=>"Other Social Infrastructure and Services", :budget=>27925630421.0}, 
			{:code=>2, :name=>"Health", :budget=>22212878878.0}, 
			{:code=>2, :name=>"Health", :budget=>21055732388.0}, 
			{:code=>9, :name=>"Banking and Financial Services", :budget=>20397424852.0}, 
			{:code=>14, :name=>"Environment", :budget=>20159410685.0}, 
			{:code=>3, :name=>"Water", :budget=>16331192363.0}, 
			{:code=>1, :name=>"Education", :budget=>14985729223.0}, 
			{:code=>12, :name=>"Industry", :budget=>14656094522.0}, 
			{:code=>2, :name=>"Health", :budget=>14000045905.0}, 
			{:code=>4, :name=>"Government and Civil Society", :budget=>12601473348.0}, 
			{:code=>4, :name=>"Government and Civil Society", :budget=>11918471223.0}, 
			{:code=>2, :name=>"Health", :budget=>11064874219.0}, 
			{:code=>6, :name=>"Transport and Storage", :budget=>8711616036.0}, 
			{:code=>2, :name=>"Health", :budget=>8010089243.0}, 
			{:code=>2, :name=>"Health", :budget=>7858745263.0}, 
			{:code=>11, :name=>"Agriculture", :budget=>7233877572.0}, 
			{:code=>1, :name=>"Education", :budget=>7204242869.0}, 
			{:code=>11, :name=>"Agriculture", :budget=>7134496360.0}, 
			{:code=>2, :name=>"Health", :budget=>6198161475.0}, 
			{:code=>3, :name=>"Water", :budget=>6183031125.0}, 
			{:code=>2, :name=>"Health", :budget=>6155833777.0}, 
			{:code=>18, :name=>"Disaster", :budget=>6122516083.0}, 
			{:code=>2, :name=>"Health", :budget=>5805871978.0}, 
			{:code=>15, :name=>"Multisector", :budget=>5730259841.0}, 
			{:code=>12, :name=>"Industry", :budget=>5478943461.0}, 
			{:code=>6, :name=>"Transport and Storage", :budget=>5147854282.0}, 
			{:code=>15, :name=>"Multisector", :budget=>5040223720.0}, 
			{:code=>4, :name=>"Government and Civil Society", :budget=>4955701101.0}, 
			{:code=>2, :name=>"Health", :budget=>4868632994.0}, 
			{:code=>1, :name=>"Education", :budget=>4757426830.0}, 
			{:code=>15, :name=>"Multisector", :budget=>4713737874.0}, 
			{:code=>18, :name=>"Disaster", :budget=>4227710748.0}, 
			{:code=>18, :name=>"Disaster", :budget=>4192151410.0}, 
			{:code=>1, :name=>"Education", :budget=>3936653823.0}, 
			{:code=>8, :name=>"Energy Generation and Supply", :budget=>3680709380.0}, 
			{:code=>4, :name=>"Government and Civil Society", :budget=>3244836444.0}, 
			{:code=>16, :name=>"Budget", :budget=>3080979644.0}, 
			{:code=>10, :name=>"Business and Other Services", :budget=>2933032823.0}, 
			{:code=>4, :name=>"Government and Civil Society", :budget=>2861248378.0}, 
			{:code=>8, :name=>"Energy Generation and Supply", :budget=>2788705529.0}, 
			{:code=>4, :name=>"Government and Civil Society", :budget=>2617799474.0}, 
			{:code=>3, :name=>"Water", :budget=>2466299528.0}, 
			{:code=>9, :name=>"Banking and Financial Services", :budget=>2392012731.0}, 
			{:code=>11, :name=>"Agriculture", :budget=>2384788542.0}, 
			{:code=>4, :name=>"Government and Civil Society", :budget=>2347974504.0}, 
			{:code=>13, :name=>"Trade ", :budget=>2345294479.0}, 
			{:code=>2, :name=>"Health", :budget=>2294576842.0}, 
			{:code=>4, :name=>"Government and Civil Society", :budget=>2159985692.0}, 
			{:code=>4, :name=>"Government and Civil Society", :budget=>2120412347.0}, 
			{:code=>13, :name=>"Trade ", :budget=>2082457253.0}, 
			{:code=>9, :name=>"Banking and Financial Services", :budget=>2060042155.0}, 
			{:code=>1, :name=>"Education", :budget=>2037514397.0}, 
			{:code=>4, :name=>"Government and Civil Society", :budget=>2019586717.0}, 
			{:code=>4, :name=>"Government and Civil Society", :budget=>2014574207.0}, 
			{:code=>1, :name=>"Education", :budget=>1983592684.0}, 
			{:code=>15, :name=>"Multisector", :budget=>1821809211.0}, 
			{:code=>3, :name=>"Water", :budget=>1767952717.0}, 
			{:code=>8, :name=>"Energy Generation and Supply", :budget=>1617798839.0}, 
			{:code=>10, :name=>"Business and Other Services", :budget=>1596740826.0}, 
			{:code=>14, :name=>"Environment", :budget=>1435115053.0}, 
			{:code=>18, :name=>"Disaster", :budget=>1428318160.0}, 
			{:code=>2, :name=>"Health", :budget=>1424660909.0}, 
			{:code=>7, :name=>"Communication ", :budget=>1344546450.0}, 
			{:code=>11, :name=>"Agriculture", :budget=>1282106389.0}, 
			{:code=>3, :name=>"Water", :budget=>1164531042.0}, 
			{:code=>14, :name=>"Environment", :budget=>1058126037.0}, 
			{:code=>11, :name=>"Forestry", :budget=>997960102.0}, 
			{:code=>11, :name=>"Agriculture", :budget=>991523833.0}, 
			{:code=>13, :name=>"Trade ", :budget=>988906784.0}, 
			{:code=>2, :name=>"Health", :budget=>931813034.0}, 
			{:code=>1, :name=>"Education", :budget=>910090000.0}, 
			{:code=>7, :name=>"Communication ", :budget=>807330429.0}, 
			{:code=>3, :name=>"Water", :budget=>777618723.0}, 
			{:code=>18, :name=>"Disaster", :budget=>762592560.0}, 
			{:code=>9, :name=>"Banking and Financial Services", :budget=>761943607.0}, 
			{:code=>5, :name=>"Other Social Infrastructure and Services", :budget=>731726080.0}, 
			{:code=>3, :name=>"Water", :budget=>601585588.0}, {:code=>11, :name=>"Agriculture", :budget=>585678108.0},
			{:code=>3, :name=>"Water", :budget=>578520087.0}, {:code=>12, :name=>"Industry", :budget=>535433407.0}, 
			{:code=>12, :name=>"Mineral Resources and Mining", :budget=>430500566.0}, 
			{:code=>3, :name=>"Water", :budget=>421946832.0}, 
			{:code=>5, :name=>"Other Social Infrastructure and Services", :budget=>400868524.0}, 
			{:code=>9, :name=>"Banking and Financial Services", :budget=>391633497.0}, 
			{:code=>22, :name=>"Unallocated", :budget=>364999230.0}, 
			{:code=>14, :name=>"Environment", :budget=>358115967.0}, 
			{:code=>4, :name=>"Government and Civil Society", :budget=>321474342.0}, 
			{:code=>13, :name=>"Trade ", :budget=>294688832.0}, 
			{:code=>1, :name=>"Education", :budget=>292674863.0}, 
			{:code=>17, :name=>"Debt", :budget=>279475989.0}, 
			{:code=>12, :name=>"Industry", :budget=>272389085.0}, 
			{:code=>4, :name=>"Government and Civil Society", :budget=>263403656.0}, 
			{:code=>1, :name=>"Education", :budget=>260022685.0}, 
			{:code=>8, :name=>"Energy Generation and Supply", :budget=>253506132.0}, 
			{:code=>4, :name=>"Government and Civil Society", :budget=>230562237.0}, 
			{:code=>5, :name=>"Other Social Infrastructure and Services", :budget=>201711002.0}, 
			{:code=>5, :name=>"Other Social Infrastructure and Services", :budget=>196418020.0}, 
			{:code=>11, :name=>"Forestry", :budget=>195195496.0}, 
			{:code=>12, :name=>"Construction", :budget=>178814043.0}, 
			{:code=>13, :name=>"Trade ", :budget=>163235936.0}, 
			{:code=>14, :name=>"Environment", :budget=>159506555.0}, 
			{:code=>3, :name=>"Water", :budget=>153868509.0}, 
			{:code=>15, :name=>"Multisector", :budget=>146720741.0}, 
			{:code=>11, :name=>"Fishing", :budget=>139262900.0}, 
			{:code=>4, :name=>"Government and Civil Society", :budget=>134612763.0}, 
			{:code=>7, :name=>"Communication ", :budget=>130845231.0}, 
			{:code=>11, :name=>"Fishing", :budget=>116825916.0}, 
			{:code=>8, :name=>"Energy Generation and Supply", :budget=>75237152.0}, 
			{:code=>7, :name=>"Communication ", :budget=>48514550.0}, 
			{:code=>13, :name=>"Trade ", :budget=>38699021.0}, 
			{:code=>3, :name=>"Water", :budget=>33999997.0}, 
			{:code=>4, :name=>"Government and Civil Society", :budget=>28556262.0}, 
			{:code=>11, :name=>"Forestry", :budget=>17067898.0}, 
			{:code=>1, :name=>"Education", :budget=>15237907.0}, 
			{:code=>5, :name=>"Other Social Infrastructure and Services", :budget=>6448132.0}, 
			{:code=>19, :name=>"Administration", :budget=>3974129.0}, 
			{:code=>14, :name=>"Environment", :budget=>242041.0}, 
			{:code=>14, :name=>"Environment", :budget=>158408.0}, 
			{:code=>11, :name=>"Fishing", :budget=>77600.0}]			

       		group_hashes input, [:code,:name]
		
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
