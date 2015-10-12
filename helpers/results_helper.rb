module ResultsHelper

	def results_pillar_wise_indicators(countryCode,resultsParsedFile)
		countryPillarData = {}
		pillarHash = {}
		countryPillarData[countryCode] = [pillarHash]
		resultsParsedFile.each do |result|
			if countryPillarData[countryCode][0].has_key?(result["pillar"])
				tempPillarData = [result["results_indicators"],result["totals"],result["Thousands"]]
				countryPillarData[countryCode][0][result["pillar"]].push(tempPillarData)
			else
				tempPillarData = [result["results_indicators"],result["totals"],result["Thousands"]]
				countryPillarData[countryCode][0][result["pillar"]] = [tempPillarData]
			end
		end
		return countryPillarData
	end
end