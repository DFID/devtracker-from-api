module DepartmentHelpers

  include CommonHelpers

  def get_department_details(deptCode)

    firstDayOfFinYear = first_day_of_financial_year(DateTime.now)
    lastDayOfFinYear = last_day_of_financial_year(DateTime.now)

  	departmentInfo = Oj.load(File.read('data/OGDs.json'))

    deptIdentifier=departmentInfo[deptCode]['identifiers']

  	activeProject = Oj.load(RestClient.get settings.oipa_api_url + "activities/?reporting_organisation="+deptIdentifier+"&hierarchy=1&format=json&fields=activity_status&page_size=250&activity_status=2")

    currentActiveProjectBudget = Oj.load(RestClient.get settings.oipa_api_url + "budgets/aggregations/?format=json&reporting_organisation="+deptIdentifier+"&budget_period_start=#{firstDayOfFinYear}&budget_period_end=#{lastDayOfFinYear}&group_by=reporting_organisation&aggregations=value&activity_status=2")

    if currentActiveProjectBudget["count"]==0 then
       totalCurrentActiveProjectBudget = 0
    else
       totalCurrentActiveProjectBudget = currentActiveProjectBudget["results"][0]["value"]  
    end   

    closedProject = Oj.load(RestClient.get settings.oipa_api_url + "activities/?reporting_organisation="+deptIdentifier+"&hierarchy=1&format=json&fields=activity_status&page_size=250&activity_status=3,4,5")

    closedProjectBudget = Oj.load(RestClient.get settings.oipa_api_url + "budgets/aggregations/?format=json&reporting_organisation="+deptIdentifier+"&group_by=reporting_organisation&aggregations=value&activity_status=3,4,5")

    countrywiseActiveProjectCount = Oj.load(RestClient.get settings.oipa_api_url + "activities/aggregations/?hierarchy=1&format=json&reporting_organisation="+deptIdentifier+"&group_by=recipient_country&aggregations=count&activity_status=2")

    puts countrywiseActiveProjectCount["results"][1].hash    

  	returnObject = {
            :code => deptCode,
            :name => departmentInfo[deptCode]["name"],
            :identifier => deptIdentifier,
            :description => departmentInfo[deptCode]["description"],
            :totalActiveProjectCount => activeProject["count"],
            :totalCurrentActiveProjectBudget => totalCurrentActiveProjectBudget,
            :totalCloseProjectCount => closedProject["count"],
            :totalCloseProjectBudget => closedProjectBudget["results"][0]["value"],
            :countrywiseActiveProjectCount => countrywiseActiveProjectCount["results"],
            }
    
  end

  def get_sect_proj_budg_data_for_department(deptCode)
    oipaAPI = RestClient.get settings.oipa_api_url + "budgets/aggregations/?format=json&reporting_organisation="+deptCode+"&activity_status=2&group_by=sector,reporting_organisation&aggregations=value&page_size=500"
    parsedJSONData = Oj.load(oipaAPI)
    parsedJSONData = parsedJSONData['results']
    # Replace the sector codes and names with their high level counter parts
    parsedJSONData.each do |data|
      if !data['sector'].nil?
        tempHighLevelSectorInfo = get_high_lvl_sect_details(data['sector']['code'].to_s)
        if !tempHighLevelSectorInfo[0].nil?
          data['sector']['code'] = tempHighLevelSectorInfo[0]['High Level Code (L1)'].to_s
          data['sector']['name'] = tempHighLevelSectorInfo[0]['High Level Sector Description'].to_s
        else
          data['sector']['code'] = '999999'
          data['sector']['name'] = 'DAC 5 sector code not in system'
        end
      end
    end

    
    
    # Sort data based on reporting organisations
    parsedJSONData = parsedJSONData.group_by{|data| data['reporting_organisation']['organisation_identifier']}
    puts parsedJSONData
    # Sum up the sector values and project counts and put them in a hash table
    dataHash = {}
    parsedJSONData.each do |key, val|
      dataHash[key] = {}
      val.each do |item|
        if item['value'] == 'null' || item['value'].nil?
          item['value'] = 0
        end
        if !dataHash[key].key?(item['sector']['code'].to_s)
          dataHash[key][item['sector']['code'].to_s] = {}
          dataHash[key][item['sector']['code'].to_s]['name'] = item['sector']['name']
          dataHash[key][item['sector']['code'].to_s]['sectorCount'] = 1
          dataHash[key][item['sector']['code'].to_s]['budget'] = item['value']
        else
          dataHash[key][item['sector']['code'].to_s]['sectorCount'] = dataHash[key][item['sector']['code'].to_s]['sectorCount'] + 1
          dataHash[key][item['sector']['code'].to_s]['budget'] = dataHash[key][item['sector']['code'].to_s]['budget'] + item['value']
        end
      end
    end
    dataHash
    
  end

end
