#require "helpers/project_helpers"

module RegionHelpers

  include ProjectHelpers
  include CommonHelpers

  def get_region_code_name(regionCode)
      regionInfo = JSON.parse(File.read('data/dfidRegions.json'))
      region = regionInfo.select {|region| region['code'] == regionCode}.first
      returnObject = {
            :code => region['code'],
            :name => region['name']
            }
  end

  def get_region_details(regionCode)

      firstDayOfFinYear = first_day_of_financial_year(DateTime.now)
      lastDayOfFinYear = last_day_of_financial_year(DateTime.now)
      
      regionInfo = JSON.parse(File.read('data/dfidRegions.json'))
      region = regionInfo.select {|region| region['code'] == regionCode}.first

      #oipa v3.1
      currentTotalRegionBudget= get_current_total_budget(RestClient.get settings.oipa_api_url + "budgets/aggregations/?format=json&reporting_organisation_identifier=#{settings.goverment_department_ids}&budget_period_start=#{firstDayOfFinYear}&budget_period_end=#{lastDayOfFinYear}&group_by=recipient_region&aggregations=value&recipient_region=#{regionCode}")
      currentTotalDFIDBudget = get_current_dfid_total_budget(RestClient.get settings.oipa_api_url + "budgets/aggregations/?format=json&reporting_organisation_identifier=#{settings.goverment_department_ids}&budget_period_start=#{firstDayOfFinYear}&budget_period_end=#{lastDayOfFinYear}&group_by=reporting_organisation&aggregations=value")
      totalProjectsDetails = get_total_project(RestClient.get settings.oipa_api_url + "activities/?reporting_organisation_identifier=#{settings.goverment_department_ids}&hierarchy=1&recipient_region=#{regionCode}&format=json&fields=activity_status&page_size=2500&activity_status=2")
      totalActiveProjects = totalProjectsDetails['results'].select {|status| status['activity_status']['code'] =="2" }.length
      totalActiveProjects = totalProjectsDetails['results'].length
      
      if currentTotalRegionBudget['count'] > 0 then
          #oipa v2.2
          #if currentTotalRegionBudget['results'][0]['budget'].nil? then
          #oipa v3.1
          if currentTotalRegionBudget['results'][0]['value'].nil? then
              regionBudget = 0
          else
              #oipa v2.2
              #regionBudget = currentTotalRegionBudget['results'][0]['budget']
              #oipa v3.1
              regionBudget = currentTotalRegionBudget['results'][0]['value']
          end    
      else
          regionBudget = 0
      end

      #oipa v2.2
      #totalDfidBudget = currentTotalDFIDBudget['results'][0]['budget']
      #oipa v3.1
      totalDfidBudget = currentTotalDFIDBudget['results'][0]['value']
      
      projectBudgetPercentToDfidBudget = ((regionBudget.round(2) / totalDfidBudget.round(2))*100).round(2)

    
      returnObject = {
            :code => region['code'],
            :name => region['name'],
            :description => region['descriptions'],
            :type => region['type'],
            :url => region['url'],
            :totalProjects => totalProjectsDetails['count'],
            :totalActiveProjects => totalActiveProjects,
            :regionBudget => regionBudget,
            :regionBudgetCurrency => "GBP",
            :projectBudgetPercentToDfidBudget => projectBudgetPercentToDfidBudget
            }
  end

  def dfid_complete_region_list(regionType)        
        regionsList = JSON.parse(File.read('data/dfidRegions.json')).select{|r| r["type"]==regionType}.sort_by{ |k| k["name"]}    
    end

    def dfid_regional_projects_data(regionType)
        
        firstDayOfFinYear = first_day_of_financial_year(DateTime.now)
        lastDayOfFinYear = last_day_of_financial_year(DateTime.now)
        if (regionType=="region")
            #oipa v3.1
            regionsDataJSON = RestClient.get settings.oipa_api_url + "budgets/aggregations/?format=json&reporting_organisation_identifier=#{settings.goverment_department_ids}&budget_period_start=#{firstDayOfFinYear}&budget_period_end=#{lastDayOfFinYear}&group_by=recipient_region&aggregations=count,value&recipient_region=298,798,89,589,389,189,679,289,380&activity_status=2"
        elsif (regionType == "regionAll")
          puts "budgets/aggregations/?format=json&reporting_organisation_identifier=#{settings.goverment_department_ids}&budget_period_start=#{firstDayOfFinYear}&budget_period_end=#{lastDayOfFinYear}&group_by=recipient_region&aggregations=count,value&recipient_region=298,798,89,589,389,189,679,289,380,998&activity_status=2"
            regionsDataJSON = RestClient.get settings.oipa_api_url + "budgets/aggregations/?format=json&reporting_organisation_identifier=#{settings.goverment_department_ids}&budget_period_start=#{firstDayOfFinYear}&budget_period_end=#{lastDayOfFinYear}&group_by=recipient_region&aggregations=count,value&recipient_region=298,798,89,589,389,189,679,289,380,998&activity_status=2"
        else
            #oipa v3.1
            regionsDataJSON = RestClient.get settings.oipa_api_url + "budgets/aggregations/?format=json&reporting_organisation_identifier=#{settings.goverment_department_ids}&budget_period_start=#{firstDayOfFinYear}&budget_period_end=#{lastDayOfFinYear}&group_by=recipient_region&aggregations=count,value&recipient_region=998"
        end

        # aggregates budgets of the dfid regional projects that are active in the current FY
        allCurrentRegions = JSON.parse(regionsDataJSON)
        allCurrentRegions = allCurrentRegions['results']

        # Map the input data structure so that it matches the required input for the Regions map
        allRegionsChartData = allCurrentRegions.map do |elem|
        {
            "region" => elem["recipient_region"]["name"].to_s.gsub(", regional",""),
            "code" => elem["recipient_region"]["code"],
            #oipa v2.2
            ###"budget" => elem["budget"]
            #oipa v3.1
            "budget" => elem["value"],
            "projects" => elem["count"]     
        }
        end
               
        # Find the total budget for all of the Regions
        totalBudget = Float(allRegionsChartData.map { |s| s["budget"].to_f }.inject(:+))

        # Format the Budget for use on the region chart
        totalBudgetFormatted = (format_million_stg totalBudget.to_f).to_s.gsub("&pound;","")

        # Format the output of the chart data
        allRegionsChartDataFormatted = allRegionsChartData.to_s.gsub("=>",":")

        returnObject = {
            :regionsDataJSON => allRegionsChartData,
            :regionsData => allRegionsChartDataFormatted,            
            :totalBudget => totalBudget,  
            :totalBudgetFormatted => totalBudgetFormatted                              
        }
    end

  #Serve the aid by location region page table data
  def generateRegionData()
    firstDayOfFinYear = first_day_of_financial_year(DateTime.now)
    lastDayOfFinYear = last_day_of_financial_year(DateTime.now)
    puts "budgets/aggregations/?format=json&reporting_organisation_identifier=#{settings.goverment_department_ids}&budget_period_start=#{firstDayOfFinYear}&budget_period_end=#{lastDayOfFinYear}&group_by=recipient_region,sector&aggregations=count,value&recipient_region=298,798,89,589,389,189,679,289,380,998"
    sectorBudgets = Oj.load(RestClient.get settings.oipa_api_url + "budgets/aggregations/?format=json&reporting_organisation_identifier=#{settings.goverment_department_ids}&budget_period_start=#{firstDayOfFinYear}&budget_period_end=#{lastDayOfFinYear}&group_by=recipient_region,sector&aggregations=count,value&recipient_region=298,798,89,589,389,189,679,289,380,998&activity_status=2")
    sectorHierarchies = Oj.load(File.read('data/sectorHierarchies.json'))
    sectorBudgets = sectorBudgets["results"]
    sectorBudgets = sectorBudgets.group_by{|key| key["recipient_region"]["code"]}
    sectorBudgets.each do |regionData|
      sectorBudgets[regionData[0]].each do |regionLevelSectorData|
        tempDAC5Code = regionLevelSectorData['sector']['code']
        pullHighLevelSectorData = sectorHierarchies.select{|key| key["Code (L3)"] == tempDAC5Code.to_i}.first
        regionLevelSectorData['sector']['code'] = pullHighLevelSectorData["High Level Code (L1)"]
        regionLevelSectorData['sector']['name'] = pullHighLevelSectorData["High Level Sector Description"]
      end
    end
    regionHash = {}
    sectorBudgets.each do |regionData|
      regionHash[regionData[0]] = {}
      sectorBudgets[regionData[0]].each do |countryLevelSectorData|
        if !regionHash[regionData[0]].key?(countryLevelSectorData['sector']['name'])
          regionHash[regionData[0]][countryLevelSectorData['sector']['name']] = {}
          regionHash[regionData[0]][countryLevelSectorData['sector']['name']]['code'] = countryLevelSectorData['sector']['code']
          regionHash[regionData[0]][countryLevelSectorData['sector']['name']]['name'] = countryLevelSectorData['sector']['name']
          regionHash[regionData[0]][countryLevelSectorData['sector']['name']]['budget'] = countryLevelSectorData['value'].to_i
        else
          regionHash[regionData[0]][countryLevelSectorData['sector']['name']]['budget'] = regionHash[regionData[0]][countryLevelSectorData['sector']['name']]['budget'].to_i + countryLevelSectorData['value'].to_i
        end
      end
    end
    regionHash.each do |key|
      regionHash[key[0]] = key[1].sort_by{ |x, y| -y["budget"] }
    end
    regionHash
  end

  def generateReportingOrgsRegionWise()
    oipa_reporting_orgs = RestClient.get settings.oipa_api_url + "activities/aggregations/?format=json&group_by=reporting_organisation,recipient_region&aggregations=count&reporting_organisation_identifier=#{settings.goverment_department_ids}&hierarchy=1&activity_status=2"
    oipa_reporting_orgs = Oj.load(oipa_reporting_orgs)
    oipa_reporting_orgs = oipa_reporting_orgs['results']
    regionHash = {}
    oipa_reporting_orgs.each do |result|
      if !regionHash.key?(result['recipient_region']['code'])
        regionHash[result['recipient_region']['code']] = Array.new
        regionHash[result['recipient_region']['code']].push(result['reporting_organisation']['organisation_identifier'])
      else
        if !regionHash[result['recipient_region']['code']].include?(result['reporting_organisation']['organisation_identifier'])
          regionHash[result['recipient_region']['code']].push(result['reporting_organisation']['organisation_identifier'])
        end
      end
    end
    regionHash
  end

  def generateActiveProjectsRegionWise()
    oipaRegionProjectCountJSON = RestClient.get settings.oipa_api_url + "activities/aggregations/?format=json&hierarchy=1&reporting_organisation_identifier=#{settings.goverment_department_ids}&group_by=recipient_region&aggregations=count&reporting_organisation_identifier=#{settings.goverment_department_ids}&activity_status=2"
    projectValues = JSON.parse(oipaRegionProjectCountJSON)
    projectCountValues = projectValues['results']
    projectCountValues = projectCountValues.group_by{|key| key['recipient_region']['code']}
    projectCountValues
  end

  def global_list
      dfid_global_projects.select { |region| region[:budget] > 0 }.sort_by { |region| region[:region].upcase}
  end

  # def dfid_global_projects_data
        
  #       globalProjectsData = JSON.parse(File.read('data/globalProjectsData.json')).sort_by{ |k| k["region"]}

  #       #Format the output of globalProjectsData
  #       globalProjectsDataFormatted = globalProjectsData.to_s.gsub("=>",":")

  #       #Find the total budget for all of the Regions
  #       totalBudget = Float(globalProjectsData.map { |s| s["budget"].to_f }.inject(:+))

  #       #Format the Budget for use on the region chart
  #       totalBudgetFormatted = (format_million_stg totalBudget.to_f).to_s.gsub("&pound;","")

  #       returnObject = {
  #           :globalData => globalProjectsDataFormatted,
  #           :globalDataJSON => globalProjectsData,
  #           :totalBudget => totalBudget,  
  #           :totalBudgetFormatted => totalBudgetFormatted                              
  #        }        

  #   end
    
    #This returns a list of countries bound by the target region
    def getCountryListForRegionMap(regionName)
      regionCountryList = dfid_complete_country_list_region_wise_sorted.sort_by{|k| k}
      targetRegionData = ''
      regionCountryList.each do |region|
        if(region[0].to_s == regionName)
          targetRegionData = region[1]
        end
      end
      targetRegionData
    end

    # Get country bounds for region for map visualisation
    def getCountryBoundsForRegions(targetRegionData)
      countryMappedFile = JSON.parse(File.read('data/country_ISO3166_mapping.json'))
      country3DigitCodeList = Array.new
      targetRegionData.each do |key,val|
        if countryMappedFile.has_key?(key.to_s)
          country3DigitCodeList.push(countryMappedFile[key])
        end
      end
      geoLocationData = ''
      geoJsonData = Array.new
      if country3DigitCodeList != ''
        geoLocationData = JSON.parse(File.read('data/world.json'))
        country3DigitCodeList.each do |countryCode|
          geoLocationData['features'].each do |loc|
            if loc['properties']['ISO_A3'].to_s == countryCode.to_s
              geoJsonData.push(loc['geometry'])
              break
            end
          end
        end
      end
      geoJsonData
    end

    #Get a list of map markers for visualisation
    def getRegionMapMarkers(regionCode)
      rawMapMarkers = JSON.parse(RestClient.get settings.oipa_api_url + "activities/?format=json&reporting_organisation_identifier=#{settings.goverment_department_ids}&hierarchy=1&recipient_region=#{regionCode}&fields=title,iati_identifier,locations&page_size=500&activity_status=2")
      rawMapMarkers = rawMapMarkers['results']
      mapMarkers = Array.new
      ar = 0
      rawMapMarkers.each do |data|
        data['locations'].each do |location|
          begin
            tempStorage = {}
            tempStorage["geometry"] = {}
            tempStorage['geometry']['type'] = 'Point'
            tempStorage['geometry']['coordinates'] = Array.new
            tempStorage['geometry']['coordinates'].push(location['point']['pos']['longitude'].to_f)
            tempStorage['geometry']['coordinates'].push(location['point']['pos']['latitude'].to_f)
            tempStorage['iati_identifier'] = location['iati_identifier']
            begin
              tempStorage['loc'] = location['name']['narratives'][0]['text']
            rescue
              tempStorage['loc'] = 'N/A'
            end
            begin
              tempStorage['title'] = data['title']['narratives'][0]['text']
            rescue
              tempStorage['title'] = 'N/A'
            end
            mapMarkers.push(tempStorage)
            ar = ar + 1
          rescue
            puts 'Data missing in API response.'
          end
        end
      end
      mapMarkers
    end
end