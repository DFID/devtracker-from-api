module FiltersHelper

	def high_level_sector_list_filter(apiUrl)
  		sectorValues  = JSON.parse(apiUrl)
  		sectorValues  = sectorValues['results']
  		highLevelSector = JSON.parse(File.read('data/sectorHierarchies.json'))

	    highLevelSectorHash = {}
	    sectorValues.each do |result|
	    	highLevelSector.find do |source|
	    		if source["Code (L3)"].to_s == result["sector"]["code"]
	    			if !highLevelSectorHash.has_key?(source["High Level Sector Description"].to_s)
	    				highLevelSectorHash[source["High Level Sector Description"].to_s] = {}
	    				highLevelSectorHash[source["High Level Sector Description"].to_s][0] = result["sector"]["code"].to_s + ","
	    				highLevelSectorHash[source["High Level Sector Description"].to_s][1] = result["count"]
	    			else
	    				highLevelSectorHash[source["High Level Sector Description"].to_s][0].concat(result["sector"]["code"].to_s + ",");
	    				highLevelSectorHash[source["High Level Sector Description"].to_s][1] = highLevelSectorHash[source["High Level Sector Description"].to_s][1] + result["count"]
	    			end
	    		end
	    	end
	    end
	    return highLevelSectorHash
	end
end