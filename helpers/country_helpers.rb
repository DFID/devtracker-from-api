module CountryHelpers

  include CommonHelpers
  # def country_project_budgets(yearWiseBudgets)
  #   projectBudgets = []
    
  #   yearWiseBudgets.each do |y|
  #     if y["quarter"]==1
  #         p=[y["quarter"],y["budget"],y["year"],y["year"]-1]
  #     else
  #         p=[y["quarter"],y["budget"],y["year"],y["year"]]
  #     end
      
  #     projectBudgets << p        
  #   end
     
  #    finYearWiseBudgets = projectBudgets.group_by{|b| b[3]}.map{|year, budgets|
  #       summedBudgets = budgets.reduce(0) {|memo, budget| memo + budget[1]}
  #       [year, summedBudgets]
  #       }.sort   

  #   # determine what range to show
  #     #current_financial_year = first_day_of_financial_year(DateTime.now)
  #     currentFinancialYear = financial_year

  #   # if range is 6 or less just show it
  #     range = if finYearWiseBudgets.size < 7 then
  #              finYearWiseBudgets
  #             # if the last item in the list is less than or equal to 
  #             # the current financial year get the last 6
  #             elsif finYearWiseBudgets.last.first <= currentFinancialYear
  #               finYearWiseBudgets.last(6)
  #             # other wise show current FY - 3 years and cuurent FY + 3 years
  #             else
  #               index_of_now = finYearWiseBudgets.index { |i| i[0] == currentFinancialYear }

  #               if index_of_now.nil? then
  #                 finYearWiseBudgets.last(6)
  #               else
  #                 finYearWiseBudgets[[index_of_now-3,0].max..index_of_now+2]
  #               end
  #             end

  #             # finally convert the range into a label format
  #             range.each { |item| 
  #               item[0] = financial_year_formatter(item[0]) 
  #             }

  # end

  def financial_year_formatter(y)
      "FY#{y.to_s[2..3]}/#{(y+1).to_s[2..3]}"
  end

  def financial_year 
    now = Time.new
    if(now.month < 4)
      now.year-1
    else
      now.year
    end
  end

  def get_top_5_countries()

      firstDayOfFinYear = first_day_of_financial_year(DateTime.now)
      lastDayOfFinYear = last_day_of_financial_year(DateTime.now)

      countriesInfo = JSON.parse(File.read('data/countries.json'))
      #newApiCall = settings.oipa_api_url_other + 'budget?q=activity_status_code:2'+add_exclusions_to_solr2()+' AND participating_org_ref:GB-* AND reporting_org_ref:(GB-GOV-1 OR GB-1) AND budget_period_start_iso_date:[2022-04-01T00:00:00Z TO *] AND budget_period_end_iso_date:[* TO 2023-03-31T00:00:00Z]&fl=budget_value,recipient_country_code,json.budget,recipient_region_code&rows=100'
      #newApiCall = settings.oipa_api_url_other + 'budget?q=activity_status_code:2 AND participating_org_ref:GB-* AND reporting_org_ref:(GB-GOV-1 OR GB-1) AND budget_period_start_iso_date:[2022-04-01T00:00:00Z TO *] AND budget_period_end_iso_date:[* TO 2023-03-31T00:00:00Z]&fl=budget_value,recipient_country_code,json.budget,recipient_region_code&rows=100'
      #oldCall = settings.oipa_api_url + "budgets/aggregations/?reporting_organisation_identifier=#{settings.goverment_department_ids}&group_by=recipient_country&aggregations=value&budget_period_start=#{firstDayOfFinYear}&budget_period_end=#{lastDayOfFinYear}&order_by=-value&page_size=10&format=json"
      #top5countriesJSON = RestClient.get  api_simple_log(settings.oipa_api_url + "budgets/aggregations/?reporting_organisation_identifier=#{settings.goverment_department_ids}&group_by=recipient_country&aggregations=value&budget_period_start=#{firstDayOfFinYear}&budget_period_end=#{lastDayOfFinYear}&order_by=-value&page_size=10&format=json")
      
      newApiCall = settings.oipa_api_url_other + "budget?q=activity_status_code:2 AND participating_org_ref:GB-* AND reporting_org_ref:(#{settings.goverment_department_ids.gsub(","," OR ")}) AND budget_period_start_iso_date:[#{firstDayOfFinYear}T00:00:00Z TO *] AND budget_period_end_iso_date:[* TO #{lastDayOfFinYear}T00:00:00Z]&fl=budget_value,recipient_country_code,json.budget,recipient_region_code&rows=5000"
      
      #top5countriesJSON = RestClient.get  api_simple_log(settings.oipa_api_url_other + "budget?q=participating_org_ref:GB-* AND reporting_org_ref:(#{settings.goverment_department_ids.gsub(","," OR ")} AND budget_period_start_iso_date:[#{firstDayOfFinYear}T00:00:00Z TO *] AND budget_period_end_iso_date:[#{lastDayOfFinYear}T00:00:00Z]&fl=budget_value,recipient_country_code,json.budget,recipient_region_code&rows=5000")
      puts settings.oipa_api_url_other + "budget?q=activity_status_code:2 AND participating_org_ref:GB-* AND reporting_org_ref:(#{settings.goverment_department_ids.gsub(","," OR ")}) AND budget_period_start_iso_date:[#{firstDayOfFinYear}T00:00:00Z TO *] AND budget_period_end_iso_date:[* TO #{lastDayOfFinYear}T00:00:00Z]&fl=budget_value,recipient_country_code,json.budget,recipient_region_code,recipient_country_name,budget_period_start_iso_date,budget_period_end_iso_date&rows=5000xx"
      #top5countries = JSON.parse(top5countriesJSON)
      newTop5countries = JSON.parse(RestClient.get settings.oipa_api_url_other + "budget?q=activity_status_code:2 AND reporting_org_ref:(#{settings.goverment_department_ids.gsub(","," OR ")}) AND budget_period_start_iso_date:[#{firstDayOfFinYear}T00:00:00Z TO *] AND budget_period_end_iso_date:[* TO #{lastDayOfFinYear}T00:00:00Z]&fl=budget_value,recipient_country_code,json.budget,recipient_region_code,recipient_country_name,budget_period_start_iso_date,budget_period_end_iso_date&rows=5000")
      puts settings.oipa_api_url_other + "budget?q=activity_status_code:2 AND participating_org_ref:GB-* AND reporting_org_ref:(#{settings.goverment_department_ids.gsub(","," OR ")}) AND budget_period_start_iso_date:[#{firstDayOfFinYear}T00:00:00Z TO *] AND budget_period_end_iso_date:[* TO #{lastDayOfFinYear}T00:00:00Z]&fl=budget_value,recipient_country_code,json.budget,recipient_region_code,recipient_country_name,budget_period_start_iso_date,budget_period_end_iso_date&rows=5000"
      newTop5countriesBudget = {}
      for item in newTop5countries['response']['docs']
        begin
          if !newTop5countriesBudget.has_key?(item['recipient_country_code'].first)
            newTop5countriesBudget[item['recipient_country_code'].first] = {}
            newTop5countriesBudget[item['recipient_country_code'].first]['name'] = item['recipient_country_name'].first
            newTop5countriesBudget[item['recipient_country_code'].first]['code'] = item['recipient_country_code'].first
            newTop5countriesBudget[item['recipient_country_code'].first]['budget'] = 0
            item['budget_value'].each_with_index do | element, index |
              if(item['budget_period_start_iso_date'][index].to_datetime >= firstDayOfFinYear && item['budget_period_end_iso_date'][index].to_datetime <= lastDayOfFinYear)
                newTop5countriesBudget[item['recipient_country_code'].first]['budget'] = newTop5countriesBudget[item['recipient_country_code'].first]['budget'] + element.to_f
              end
            end
          else
            item['budget_value'].each_with_index do | element, index |
              if(item['budget_period_start_iso_date'][index].to_datetime >= firstDayOfFinYear && item['budget_period_end_iso_date'][index].to_datetime <= lastDayOfFinYear)
                newTop5countriesBudget[item['recipient_country_code'].first]['budget'] = newTop5countriesBudget[item['recipient_country_code'].first]['budget'] + element.to_f
              end
            end
          end
        rescue
          
        end
      end
      finalResult = []
      newTop5countriesBudget.each do |key, val|
        finalResult.push(val)
      end
      # top5countriesBudget = top5countries["results"].map do |elem| 
      #    {  
      #       :code     => elem["recipient_country"]["code"],  
      #       :name     => countriesInfo.find do |source|
      #                      source["code"].to_s == elem["recipient_country"]["code"]
      #                    end["name"],
      #       :budget   => elem["value"].to_i                                                                                  
      #    } 
      # end
      finalResult
  end

  def get_country_code_name(countryCode)
    countriesInfo = Oj.load(File.read('data/countries.json'))
    country = countriesInfo.select {|country| country['code'].to_s == countryCode.to_s}.first
    returnObject = {
          'code' => country['code'],
          'name' => country['name']
        }
  end


  def get_country_detailsv2(countryCode)

    firstDayOfFinYear = first_day_of_financial_year(DateTime.now)
    lastDayOfFinYear = last_day_of_financial_year(DateTime.now)
    
    countriesInfo = Oj.load(File.read('data/countries.json'))
    country = countriesInfo.select {|country| country['code'] == countryCode}.first
    
    ## new api call
    newApiCall = settings.oipa_api_url_other + "budget?q=participating_org_ref:GB-* AND reporting_org_ref:(#{settings.goverment_department_ids.gsub(","," OR ")}) AND budget_period_start_iso_date:[#{settings.current_first_day_of_financial_year}T00:00:00Z TO *] AND budget_period_end_iso_date:[* TO #{settings.current_last_day_of_financial_year}T00:00:00Z] AND recipient_country_code:#{countryCode}&fl=iati_identifier,budget_value,recipient_country_code,recipient_region_code,budget_period_start_iso_date,budget_period_end_iso_date,sector_code,sector_percentage,budget_value_gbp&rows=50000"
		pulledData = RestClient.get newApiCall
    pulledData  = JSON.parse(pulledData)['response']['docs']
    countryBudget = 0
    pulledData.each do |element|
      if (element.has_key?('recipient_country_code'))
        tempTotalBudget = 0
        element['budget_period_start_iso_date'].each_with_index do |data, index|
            if(data.to_datetime >= settings.current_first_day_of_financial_year && element['budget_period_end_iso_date'][index].to_datetime <= settings.current_last_day_of_financial_year)
                tempTotalBudget = tempTotalBudget + element['budget_value_gbp'][index].to_f
            end
        end
        countryBudget = countryBudget + tempTotalBudget
      end
    end
    ##
    #oipa v3.1
    #currentTotalCountryBudget= get_current_total_budget(RestClient.get  api_simple_log(settings.oipa_api_url + "budgets/aggregations/?format=json&reporting_organisation_identifier=#{settings.goverment_department_ids}&budget_period_start=#{firstDayOfFinYear}&budget_period_end=#{lastDayOfFinYear}&group_by=recipient_country&aggregations=value&recipient_country=#{countryCode}"))

    # if currentTotalCountryBudget['count'] > 0 then
    #     #oipa v2.2
    #     #countryBudget = currentTotalCountryBudget['results'][0]['budget']
    #     #oipa v3.1
    #     countryBudget = currentTotalCountryBudget['results'][0]['value']
    # else
    #     countryBudget = 0
    # end
  
    returnObject = {
          :code => country['code'],
          :name => country['name'],
          :description => country['description'],
          :population => country['population'],
          :population_year => country['population_year'],
          :lifeExpectancy => country['lifeExpectancy'],
          :incomeLevel => country['incomeLevel'],
          :belowPovertyLine => country['belowPovertyLine'],
          :belowPovertyLine_year => country['belowPovertyLine_year'],
          :fertilityRate => country['fertilityRate'],
          :fertilityRate_year => country['fertilityRate_year'],
          :gdpGrowthRate => country['gdpGrowthRate'],
          :gdpGrowthRate_year => country['gdpGrowthRate_year'],
          :countryBudget => countryBudget,
          :countryBudgetCurrency => "GBP",
          }
  end

  def get_country_details(countryCode)

      firstDayOfFinYear = first_day_of_financial_year(DateTime.now)
      lastDayOfFinYear = last_day_of_financial_year(DateTime.now)
      
      countriesInfo = Oj.load(File.read('data/countries.json'))
      country = countriesInfo.select {|country| country['code'] == countryCode}.first
            
      #oipa v3.1
      currentTotalCountryBudget= get_current_total_budget(RestClient.get  api_simple_log(settings.oipa_api_url + "budgets/aggregations/?format=json&reporting_organisation_identifier=#{settings.goverment_department_ids}&budget_period_start=#{firstDayOfFinYear}&budget_period_end=#{lastDayOfFinYear}&group_by=recipient_country&aggregations=value&recipient_country=#{countryCode}"))

      if currentTotalCountryBudget['count'] > 0 then
          #oipa v2.2
          #countryBudget = currentTotalCountryBudget['results'][0]['budget']
          #oipa v3.1
          countryBudget = currentTotalCountryBudget['results'][0]['value']
      else
          countryBudget = 0
      end
    
      returnObject = {
            :code => country['code'],
            :name => country['name'],
            :description => country['description'],
            :population => country['population'],
            :population_year => country['population_year'],
            :lifeExpectancy => country['lifeExpectancy'],
            :incomeLevel => country['incomeLevel'],
            :belowPovertyLine => country['belowPovertyLine'],
            :belowPovertyLine_year => country['belowPovertyLine_year'],
            :fertilityRate => country['fertilityRate'],
            :fertilityRate_year => country['fertilityRate_year'],
            :gdpGrowthRate => country['gdpGrowthRate'],
            :gdpGrowthRate_year => country['gdpGrowthRate_year'],
            :countryBudget => countryBudget,
            :countryBudgetCurrency => "GBP",
            }
  end

  

  def get_country_results(countryCode)
      resultsInfo = Oj.load(File.read('data/results.json'))
      results = resultsInfo.select {|result| result['code'] == countryCode}
  end


  def get_country_or_region(projectId)
      #get the data
      # if is_dfid_project(projectId) then
      #    countryOrRegionAPI = RestClient.get  api_simple_log(settings.oipa_api_url + "activities/?related_activity_id=#{projectId}&fields=iati_identifier,recipient_countries,recipient_regions&hierarchy=2&format=json&page_size=500")
      # else
      #    countryOrRegionAPI = RestClient.get  api_simple_log(settings.oipa_api_url + "activities/?iati_identifier=#{projectId}&fields=iati_identifier,recipient_countries,recipient_regions&format=json&page_size=500")
      # end
      countryOrRegionAPI = RestClient.get  api_simple_log(settings.oipa_api_url + "activities/?iati_identifier=#{projectId}&fields=iati_identifier,recipient_country,recipient_region&format=json&page_size=500")
      countryOrRegionData = JSON.parse(countryOrRegionAPI)
      data = countryOrRegionData['results']
      data.each do |d|
        begin
          d['recipient_country'][0].delete('id')
          #This is a special check in place because the API is returning a different name
          if(d['recipient_country'][0]['country']['code'].to_s == 'PS')
            d['recipient_country'][0]['country']['name'] = 'Occupied Palestinian Territories (OPT)'
          end
        rescue
        end
        begin
          d['recipient_region'][0].delete('id')
        rescue
        end
      end
      #iterate through the array
      #countries = data.collect{ |activity| activity['recipient_countries'][0]}.uniq.compact
      #regions = data.collect{ |activity| activity['recipient_regions'][0]}.uniq.compact
      countries = data[0]['recipient_country']
      regions = data[0]['recipient_region']
      #project type logic
      if(!countries.empty?) then 
        numberOfCountries = countries.count
      else 
        numberOfCountries = 0
      end

      if(!regions.empty?) then 
        numberOfRegions = regions.count
      else numberOfRegions = 0
      end

      #single country case
      if(numberOfCountries == 1 && numberOfRegions == 0) then 
        projectType = "country"
        name = countries[0]['country']['name']
        code = countries[0]['country']['code']
        breadcrumbLabel = name
        breadcrumbUrl = "/countries/" + code
      #single region case
      elsif (numberOfRegions == 1 && numberOfCountries == 0) then 
        projectType = "region"
        name = regions[0]['region']['name']
        code = regions[0]['region']['code']
        breadcrumbLabel = name
        breadcrumbUrl = "/regions/" + code
      #other cases - multiple countries/regions
      #elsif (numberOfRegions > 1 && numberOfCountries == 0) then
      #  projectType = "region"
      else 
        projectType = "global"
        breadcrumbLabel = "Global"
        breadcrumbUrl = "/location/global"
      end

      #generate the text label for the country or region
      globalLabel = []
      countries.map do |c|
        country = get_country_code_name(c['country']['code'])
        globalLabel << country[:name]
      end
      regions.map do |r|
        globalLabel << r['region']['name']
      end
      label = globalLabel.sort.join(", ")

      if (label.length == 0 && projectType == "global") then 
        label = "Global project" 
      end
      puts 'country or region details sgrabbed'
      returnObject = {
            :recipient_countries  => countries,
            :recipient_regions => regions,
            :name => name,
            :code => code,
            :projectType => projectType,
            :label => label,
            :breadcrumbLabel => breadcrumbLabel,
            :breadcrumbUrl => breadcrumbUrl,
            :countriesCount => numberOfCountries,
            :regionsCount => numberOfRegions
            }
  end

  def get_country_or_regionv2(projectId)
    # countryOrRegionAPI = RestClient.get  api_simple_log(settings.oipa_api_url_other + "/activity/?q=iati_identifier:#{projectId}&fl=iati_identifier,recipient_country_name,recipient_country_code,recipient_region_code,recipient_region_name")
    # #countryOrRegionAPI = RestClient.get  api_simple_log(settings.oipa_api_url + "activities/?iati_identifier=#{projectId}&fields=iati_identifier,recipient_country,recipient_region&format=json&page_size=500")
    # countryOrRegionData = JSON.parse(countryOrRegionAPI)['response']['docs'].first
    # data = countryOrRegionData
    # data.each do |d|
    #   begin
    #     d['recipient_country'][0].delete('id')
    #     #This is a special check in place because the API is returning a different name
    #     if(d['recipient_country'][0]['country']['code'].to_s == 'PS')
    #       d['recipient_country'][0]['country']['name'] = 'Occupied Palestinian Territories (OPT)'
    #     end
    #   rescue
    #   end
    #   begin
    #     d['recipient_region'][0].delete('id')
    #   rescue
    #   end
    # end
    # #iterate through the array
    # countries = data[0]['recipient_country']
    # regions = data[0]['recipient_region']
    # #project type logic
    # if(!countries.empty?) then 
    #   numberOfCountries = countries.count
    # else 
    #   numberOfCountries = 0
    # end

    # if(!regions.empty?) then 
    #   numberOfRegions = regions.count
    # else numberOfRegions = 0
    # end

    # #single country case
    # if(numberOfCountries == 1 && numberOfRegions == 0) then 
    #   projectType = "country"
    #   name = countries[0]['country']['name']
    #   code = countries[0]['country']['code']
    #   breadcrumbLabel = name
    #   breadcrumbUrl = "/countries/" + code
    # #single region case
    # elsif (numberOfRegions == 1 && numberOfCountries == 0) then 
    #   projectType = "region"
    #   name = regions[0]['region']['name']
    #   code = regions[0]['region']['code']
    #   breadcrumbLabel = name
    #   breadcrumbUrl = "/regions/" + code
    # #other cases - multiple countries/regions
    # #  projectType = "region"
    # else 
    #   projectType = "global"
    #   breadcrumbLabel = "Global"
    #   breadcrumbUrl = "/location/global"
    # end

    # #generate the text label for the country or region
    # globalLabel = []
    # countries.map do |c|
    #   country = get_country_code_name(c['country']['code'])
    #   globalLabel << country[:name]
    # end
    # regions.map do |r|
    #   globalLabel << r['region']['name']
    # end
    # label = globalLabel.sort.join(", ")

    # if (label.length == 0 && projectType == "global") then 
    #   label = "Global project" 
    # end
    # puts 'country or region details sgrabbed'
    #############################################
    countryOrRegionAPI = RestClient.get  api_simple_log(settings.oipa_api_url_other + "/activity/?q=iati_identifier:#{projectId}&fl=iati_identifier,recipient_country_name,recipient_country_code,recipient_region_code,recipient_region_name,recipient_country_percentage,recipient_region_percentage")
    countryOrRegionData = JSON.parse(countryOrRegionAPI)['response']['docs'].first
    countries = []
    regions = []
    numberOfCountries = 0
    numberOfRegions = 0
    if(countryOrRegionData.has_key?('recipient_country_code'))
      if(countryOrRegionData['recipient_country_code'].count > 0)
        numberOfCountries = countryOrRegionData['recipient_country_code'].count
        countryOrRegionData['recipient_country_code'].each_with_index do |item, index|
          tempData = {}
          tempData['country'] = {}
          tempData['country']['code'] = item
          tempData['country']['name'] = countryOrRegionData['recipient_country_name'][index]
          tempData['percentage'] = countryOrRegionData.has_key?('recipient_country_percentage') ? countryOrRegionData['recipient_country_percentage'][index] : 0
          countries.push(tempData)
        end
      else
        numberOfCountries = 0
      end
    else
      numberOfCountries = 0
    end
    if(countryOrRegionData.has_key?('recipient_region_code'))
      if(countryOrRegionData['recipient_region_code'].count > 0)
        numberOfRegions = countryOrRegionData['recipient_region_code'].count
        countryOrRegionData['recipient_region_code'].each_with_index do |item, index|
          tempData = {}
          tempData['region'] = {}
          tempData['region']['code'] = item
          tempData['region']['name'] = countryOrRegionData['recipient_region_name'][index]
          tempData['percentage'] = countryOrRegionData.has_key?('recipient_region_percentage') ? countryOrRegionData['recipient_region_percentage'][index] : 0
          regions.push(tempData)
        end
      else
        numberOfRegions = 0
      end
    else
      numberOfRegions = 0
    end
    if(numberOfCountries == 1 && numberOfRegions == 0) then 
      projectType = "country"
      name = countries.first['country']['name']
      code = countries.first['country']['code']
      breadcrumbLabel = name
      breadcrumbUrl = "/countries/" + code
    #single region case
    elsif (numberOfRegions == 1 && numberOfCountries == 0) then 
      projectType = "region"
      name = regions.first['region']['name']
      code = regions.first['region']['code']
      breadcrumbLabel = name
      breadcrumbUrl = "/regions/" + code
    #other cases - multiple countries/regions
    #  projectType = "region"
    else 
      projectType = "global"
      breadcrumbLabel = "Global"
      breadcrumbUrl = "/location/global"
    end
    #generate the text label for the country or region
    globalLabel = []
    countries.map do |c|
      country = get_country_code_name(c['country']['code'])
      globalLabel << country['name']
    end
    regions.map do |r|
      globalLabel << r['region']['name']
    end
    print(globalLabel)
    label = globalLabel.sort.join(", ")

    if (label.length == 0 && projectType == "global") then 
      label = "Global project" 
    end
    returnObject = {
          :recipient_countries  => countries,
          :recipient_regions => regions,
          :name => name,
          :code => code,
          :projectType => projectType,
          :label => label,
          :breadcrumbLabel => breadcrumbLabel,
          :breadcrumbUrl => breadcrumbUrl,
          :countriesCount => numberOfCountries,
          :regionsCount => numberOfRegions
          }
  end

  def budgetBarGraphData(apiLink)
    tempInfo = get_reporting_orgWise_yearly_country_budgets(RestClient.get  api_simple_log(settings.oipa_api_url + apiLink))
    reportingOrgList = []
    reportingOrgList = tempInfo.keys
    finYearList = []
    tempInfo.each do |v|
      tempArr = []
      tempArr = v[1].keys
      finYearList = (finYearList+tempArr).uniq
    end
    finYearList = finYearList.sort
    columnData = {}
    reportingOrgList.each do |o|
      tempData = []
      i = finYearList.length
      j = 0
      while j < i
        tempData.push(0)
        j = j + 1
      end
      columnData[o] = {}
      columnData[o] = tempData
    end
    tempInfo.each do |key, val|
      val.each do |k , v|
        columnData[key][finYearList.index(k)] = v
      end
    end
    finalData = []
    columnData.each do |key, val|
      tempData = []
      tempData.push(key)
      tempData = tempData + val
      finalData.push(tempData)
    end
    finalData.each do |x|
      x[0] = returnDepartmentName(x[0])
    end
    finalReportingOrgList = []
    reportingOrgList.each do |x|
      finalReportingOrgList.push(returnDepartmentName(x))
    end
    data = []
    data.push(finalReportingOrgList)
    data.push(finYearList)
    data.push(finalData)
    data
  end

  def budgetBarGraphDataD(apiLink, type)
    if type == 'i'
      tempInfo = get_reporting_orgWise_yearly_country_budgetsSplit(RestClient.get  api_simple_log(apiLink))  
    else
      tempInfo = get_reporting_orgWise_yearly_country_budgetsD(RestClient.get  api_simple_log(apiLink))
    end
    reportingOrgList = []
    reportingOrgList = tempInfo.keys
    finYearList = []
    tempInfo.each do |v|
      tempArr = []
      tempArr = v[1].keys
      finYearList = (finYearList+tempArr).uniq
    end
    finYearList = finYearList.sort
    columnData = {}
    reportingOrgList.each do |o|
      tempData = []
      i = finYearList.length
      j = 0
      while j < i
        tempData.push(0)
        j = j + 1
      end
      columnData[o] = {}
      columnData[o] = tempData
    end
    tempInfo.each do |key, val|
      val.each do |k , v|
        columnData[key][finYearList.index(k)] = v.to_f.floor(2)
      end
    end
    finalData = []
    columnData.each do |key, val|
      tempData = []
      tempData.push(key)
      tempData = tempData + val
      finalData.push(tempData)
    end
    finalData.each do |x|
      x[0] = returnDepartmentName(x[0])
    end
    finalReportingOrgList = []
    reportingOrgList.each do |x|
      finalReportingOrgList.push(returnDepartmentName(x))
    end
    data = []
    data.push(finalReportingOrgList)
    data.push(finYearList)
    data.push(finalData)
    data
  end

  def budgetBarGraphDataDv2(countryCode)
    #Process budgets
    apiData = RestClient.get api_simple_log(settings.oipa_api_url_other + "activity/?q=recipient_country_code:#{countryCode} AND reporting_org_ref:GB-GOV-*&fl=reporting_org_narrative,reporting_org_ref,budget.period-start.quarter,transaction.transaction-date.quarter,transaction_type,transaction_date_iso_date,transaction_value,budget_value_gbp,budget_period_start_iso_date,budget_period_end_iso_date,budget_value&start=0&rows=100")
    apiData = JSON.parse(apiData)['response']['docs']
    fyTracker = []
    repOrgs = {}
    apiData.each do |activity|
      if activity.has_key?('budget_period_start_iso_date')
          activity['budget_period_start_iso_date'].each_with_index do |item, index|
            if !repOrgs.has_key?(activity['reporting_org_ref'])
              repOrgs[activity['reporting_org_ref']] = {}
              repOrgs[activity['reporting_org_ref']]['orgName'] = activity['reporting_org_narrative'].first
              repOrgs[activity['reporting_org_ref']]['orgFinYears'] = {}
            end
            t = Time.parse(item)
            fy = if activity['budget.period-start.quarter'][index].to_i == 1 then t.year - 1 else t.year end
            if repOrgs[activity['reporting_org_ref']]['orgFinYears'].has_key?(fy)
              repOrgs[activity['reporting_org_ref']]['orgFinYears'][fy] = repOrgs[activity['reporting_org_ref']]['orgFinYears'][fy] + activity['budget_value'][index]
            else
              repOrgs[activity['reporting_org_ref']]['orgFinYears'][fy] = activity['budget_value'][index]
              if !fyTracker.include?(fy)
                fyTracker.push(fy)
              end
            end
          end
      end
    end
    repOrgs
    fyTracker.sort!
    titleArray = []
    fyArray = []
    dataArray = []
    repOrgs.each do |key, val|
      titleArray.push(val['orgName'])
      tempDataArray = []
      tempDataArray.push(val['orgName'])
      fyTracker.each do |fy|
        if val['orgFinYears'].has_key?(fy)
          tempDataArray.push(val['orgFinYears'][fy].round(2))
        else
          tempDataArray.push(0)
        end
      end
      dataArray.push(tempDataArray)
    end
    fyTracker.each do |item|
      e = item+1
      f = 'FY' + item.to_s.chars.last(2).join + '/' + e.to_s.chars.last(2).join
      fyArray.push(f)
    end
    finalData = []
    finalData.push(titleArray)
    finalData.push(fyArray)
    finalData.push(dataArray)
    finalData
  end


  def get_country_region_yearwise_budget_graph_data(apiLink)

      yearWiseBudgets = Oj.load(apiLink)
      #oipa v2.2
      #yearWiseBudgets['results'] = yearWiseBudgets['results'].select {|project| !project['budget'].nil?}
      #oipa v3.1
      yearWiseBudgets['results'] = yearWiseBudgets['results'].select {|project| !project['value'].nil?}
      budgetYearData = financial_year_wise_budgets(yearWiseBudgets['results'],"C")

  end

  def get_country_region_yearwise_budget_graph_datav2(apiLink)

    yearWiseBudgets = Oj.load(apiLink)['response']['docs']
    #oipa v2.2
    #yearWiseBudgets['results'] = yearWiseBudgets['results'].select {|project| !project['budget'].nil?}
    #oipa v3.1
    budgetYearData = financial_year_wise_budgetsv2(yearWiseBudgets,"C")

end

  def get_reporting_orgWise_yearly_country_budgets(apiLink)
    allBudgets = Oj.load(apiLink)
    reportingOrgWiseData = {}
    allBudgets['results'].each do |budget|
      if(!reportingOrgWiseData.key?(budget['reporting_org']['reporting_org']['ref']))
        reportingOrgWiseData[budget['reporting_org']['reporting_org']['ref']] = []
      end
      tempData = {}
      tempData['budget_period_start_year'] = budget['budget_period_start_year']
      tempData['budget_period_start_quarter'] = budget['budget_period_start_quarter']
      tempData['value'] = budget['value']
      reportingOrgWiseData[budget['reporting_org']['reporting_org']['ref']].push(tempData)
    end
    reportingOrgWiseData.each do |key, value|
      value = value.select {|val| !val['value'].nil?}
      reportingOrgWiseData[key] = {}
      reportingOrgWiseData[key] = financial_year_wise_budgets(value, 'C2')
    end
    reportingOrgWiseData
  end
  
  def get_reporting_orgWise_yearly_country_budgetsD(apiLink)
    allBudgets = Oj.load(apiLink)
    reportingOrgWiseData = {}
    allBudgets['result'].each do |budget|
      if(!reportingOrgWiseData.key?(budget['reporting_organisation'].to_s))
        reportingOrgWiseData[budget['reporting_organisation']] = []
      end
      tempData = {}
      tempData['budget_period_start_year'] = budget['budget_period_start_year']
      tempData['budget_period_start_quarter'] = budget['budget_period_start_quarter']
      tempData['value'] = budget['value']
      reportingOrgWiseData[budget['reporting_organisation']].push(tempData)
    end
    reportingOrgWiseData.each do |key, value|
      value = value.select {|val| !val['value'].nil?}
      reportingOrgWiseData[key] = {}
      reportingOrgWiseData[key] = financial_year_wise_budgets(value, 'C2')
    end
    reportingOrgWiseData
  end

  def get_reporting_orgWise_yearly_country_budgetsSplit(apiLink)
    allBudgets = Oj.load(apiLink)
    reportingOrgWiseData = {}
    allBudgets['results'].each do |budget|
      if(!reportingOrgWiseData.key?(budget['reporting_organisation']['organisation_identifier'].to_s))
        reportingOrgWiseData[budget['reporting_organisation']['organisation_identifier']] = []
      end
      tempData = {}
      tempData['budget_period_start_year'] = budget['budget_period_start_year']
      tempData['budget_period_start_quarter'] = budget['budget_period_start_quarter']
      tempData['value'] = budget['value']
      reportingOrgWiseData[budget['reporting_organisation']['organisation_identifier']].push(tempData)
    end
    reportingOrgWiseData.each do |key, value|
      value = value.select {|val| !val['value'].nil?}
      reportingOrgWiseData[key] = {}
      reportingOrgWiseData[key] = financial_year_wise_budgets(value, 'C2')
    end
    reportingOrgWiseData
  end

  def get_country_sector_graph_data(countrySpecificsectorValuesJSONLink)
      budgetArray = Array.new
      resultCount = Oj.load(countrySpecificsectorValuesJSONLink)
      c3ReadyDonutData = Array.new
      if resultCount["count"] > 0
          highLevelSectorListData = high_level_sector_list( countrySpecificsectorValuesJSONLink, "all_sectors", "High Level Code (L1)", "High Level Sector Description")
          sectorWithTopBudgetHash = {}
          highLevelSectorListData[:sectorsData].each do |sector|
            sectorGroupPercentage = (100*sector[:budget].to_f/highLevelSectorListData[:totalBudget].to_f).round(2)
            sectorWithTopBudgetHash[sector[:name]] = sectorGroupPercentage
            budgetArray.push(sectorGroupPercentage)
          end
          budgetArray.sort!
          #Fixing the donut data here
          topFiveTracker = 0
          c3ReadyDonutData[0] = ''
          otherBudgetPercentage = 0.0
          c3ReadyDonutData[1] = '['
          while !budgetArray.empty?
            if(topFiveTracker < 5)
              topFiveTracker = topFiveTracker + 1
              tempBudgetValue = budgetArray.pop
              c3ReadyDonutData[0].concat("['"+sectorWithTopBudgetHash.key(tempBudgetValue)+"',"+tempBudgetValue.to_s+"],")
              c3ReadyDonutData[1].concat("'"+sectorWithTopBudgetHash.key(tempBudgetValue)+"',")
            else
              otherBudgetPercentage = otherBudgetPercentage + budgetArray.pop
            end
          end
          if(topFiveTracker == 5)
            c3ReadyDonutData[0].concat("['Others',"+ otherBudgetPercentage.round(2).to_s+"]")
            c3ReadyDonutData[1].concat("'Others']")
            return c3ReadyDonutData
          else
            c3ReadyDonutData[1].concat(']')
            return c3ReadyDonutData
          end
      else
          c3ReadyDonutData[0] = '["No data available for this view",0]'
          c3ReadyDonutData[1] = "['No data available for this view']"
          return c3ReadyDonutData
      end
  end

  def get_country_sector_graph_data_jsCompatible(countrySpecificsectorValuesJSONLink)
    budgetArray = Array.new
    resultCount = Oj.load(countrySpecificsectorValuesJSONLink)
    c3ReadyDonutData = Array.new
    if resultCount["count"] > 0
        highLevelSectorListData = high_level_sector_list( countrySpecificsectorValuesJSONLink, "all_sectors", "High Level Code (L1)", "High Level Sector Description")
        sectorWithTopBudgetHash = {}
        highLevelSectorListData[:sectorsData].each do |sector|
          sectorGroupPercentage = (100*sector[:budget].to_f/highLevelSectorListData[:totalBudget].to_f).round(2)
          sectorWithTopBudgetHash[sector[:name]] = sectorGroupPercentage
          budgetArray.push(sectorGroupPercentage)
        end
        budgetArray.sort!
        #Fixing the donut data here
        topFiveTracker = 0
        c3ReadyDonutData[0] = []
        otherBudgetPercentage = 0.0
        c3ReadyDonutData[1] = []
        while !budgetArray.empty?
          if(topFiveTracker < 5)
            topFiveTracker = topFiveTracker + 1
            tempBudgetValue = budgetArray.pop
            tempData = []
            tempData.push(sectorWithTopBudgetHash.key(tempBudgetValue))
            tempData.push(tempBudgetValue)
            c3ReadyDonutData[0].push(tempData)
            #c3ReadyDonutData[0].concat("['"+sectorWithTopBudgetHash.key(tempBudgetValue)+"',"+tempBudgetValue.to_s+"],")
            c3ReadyDonutData[1].push(sectorWithTopBudgetHash.key(tempBudgetValue))

            #c3ReadyDonutData[1].concat("'"+sectorWithTopBudgetHash.key(tempBudgetValue)+"',")
          else
            otherBudgetPercentage = otherBudgetPercentage + budgetArray.pop
          end
        end
        if(topFiveTracker == 5)
          tempData = []
          tempData.push('Others')
          tempData.push(otherBudgetPercentage.round(2))
          c3ReadyDonutData[0].push(tempData)
          #c3ReadyDonutData[0].concat("['Others',"+ otherBudgetPercentage.round(2).to_s+"]")
          #c3ReadyDonutData[1].concat("'Others']")
          c3ReadyDonutData[1].push('Others')
          return c3ReadyDonutData
        else
          # c3ReadyDonutData[1].concat(']')
          return c3ReadyDonutData
        end
    else
        #c3ReadyDonutData[0] = '["No data available for this view",0]'
        tempData = []
        tempData.push("No data available for this view")
        tempData.push(0)
        c3ReadyDonutData[0].push(tempData)
        c3ReadyDonutData[1].push('No data available for this view')
        return c3ReadyDonutData
    end
  end

  def get_country_sector_graph_data_jsCompatibleV2(countryCode)
    secHi = JSON.parse(File.read('data/sectorHierarchies.json'))
    api = RestClient.get settings.oipa_api_url_other + "activity/?q=recipient_country_code:#{countryCode} AND reporting_org_ref:GB-GOV-*&fl=sector*,iati_identifier,child_aggregation_budget_value_gbp&start=0&rows=1000"
    pulledData = JSON.parse(api)['response']['docs']
    sectorBudgets = {}
    totalBudget = 0
    pulledData.each do |activity|
      if activity.has_key?('sector_code') && activity.has_key?('child_aggregation_budget_value_gbp') && activity.has_key?('sector_percentage') 
        activity['sector_code'].each_with_index do |s, i|
          if !secHi.find_index{|k,_| k['Code (L3)'].to_i == s.to_i}.nil?
            selectedHiLvlSectorData = secHi.find{|k,_| k['Code (L3)'].to_i == s.to_i}
            if !sectorBudgets.has_key?(selectedHiLvlSectorData['High Level Sector Description'])
              sectorBudgets[selectedHiLvlSectorData['High Level Sector Description']] = ((activity['child_aggregation_budget_value_gbp'].to_f/100)*activity['sector_percentage'][i].to_f)
              totalBudget = totalBudget + ((activity['child_aggregation_budget_value_gbp'].to_f/100)*activity['sector_percentage'][i].to_f)
            else
              sectorBudgets[selectedHiLvlSectorData['High Level Sector Description']] = sectorBudgets[selectedHiLvlSectorData['High Level Sector Description']] + ((activity['child_aggregation_budget_value_gbp'].to_f/100)*activity['sector_percentage'][i].to_f)
              totalBudget = totalBudget + ((activity['child_aggregation_budget_value_gbp'].to_f/100)*activity['sector_percentage'][i].to_f)
            end
          end
        end
      end
    end
    c3ReadyDonutData = []
    c3ReadyDonutData[0] = []
    c3ReadyDonutData[1] = []
    otherBudget = 0
    fBud = 0
    sectorBudgets.sort_by {|_key, value| -value}
    sectorBudgets.update(sectorBudgets) {|key, val| val/totalBudget*100}
    counter = 0
    sectorBudgets.each do |key, val|
      if (counter < 5)
        tempData = []
        tempData.push(key)
        tempData.push(val.round(2))
        c3ReadyDonutData[0].push(tempData)
        c3ReadyDonutData[1].push(key)
        counter = counter + 1
      else
        otherBudget = otherBudget + val
      end
    end
    if counter == 5
      tempData = []
      tempData.push('Others')
      tempData.push(otherBudget.round(2))
      c3ReadyDonutData[0].push(tempData)
      c3ReadyDonutData[1].push('Others')
    end
    c3ReadyDonutData
  end

  def get_country_all_projects_rss(countryCode)
    rssJSON = RestClient.get  api_simple_log(settings.oipa_api_url + "activities/?format=json&reporting_org_identifier=#{settings.goverment_department_ids}&hierarchy=1&related_activity_recipient_country=#{countryCode}&ordering=-last_updated_datetime&fields=last_updated_datetime,title,descriptions,iati_identifier&page_size=500")
    rssData = JSON.parse(rssJSON)
    rssResults = rssData['results']
  end
  
  def total_country_budget_locationv2
    newApiCall = settings.oipa_api_url_other + "budget?q=participating_org_ref:GB-* AND reporting_org_ref:(#{settings.goverment_department_ids.gsub(","," OR ")}) AND budget_period_start_iso_date:[#{settings.current_first_day_of_financial_year}T00:00:00Z TO *] AND budget_period_end_iso_date:[* TO #{settings.current_last_day_of_financial_year}T00:00:00Z] AND recipient_country_code:*&fl=recipient_country_code,budget_period_start_iso_date,budget_period_end_iso_date,budget_value_gbp,recipient_country_name&rows=50000"
    pulledData = RestClient.get newApiCall
    pulledData  = JSON.parse(pulledData)['response']['docs']
    totalBudget = 0
    pulledData.each do |element|
      if (element.has_key?('recipient_country_code'))
        tempTotalBudget = 0
        element['budget_period_start_iso_date'].each_with_index do |data, index|
            if(data.to_datetime >= settings.current_first_day_of_financial_year && element['budget_period_end_iso_date'][index].to_datetime <= settings.current_last_day_of_financial_year)
                tempTotalBudget = tempTotalBudget + element['budget_value_gbp'][index].to_f
            end
        end
        totalBudget = totalBudget + tempTotalBudget
      end
    end
    totalAmount = (format_million_stg totalBudget.to_f).to_s.gsub("&pound;","")
    totalAmount
    ########
    #oipa 3.1
    # totalCountryBudgetLocation = RestClient.get  api_simple_log(settings.oipa_api_url + "budgets/aggregations/?reporting_organisation_identifier=#{settings.goverment_department_ids}&group_by=recipient_country&aggregations=value&budget_period_start=#{firstDayOfFinYear}&budget_period_end=#{lastDayOfFinYear}&format=json&order_by=-value")
    # totalCountryBudgetLocation = JSON.parse(totalCountryBudgetLocation)
    # totalAmount = 0.0
    # totalCountryBudgetLocation['results'].each do |countryBudgets|
    #   #oipa 2.2
    #   #totalAmount = totalAmount + countryBudgets['budget'].to_f
    #   #oipa 3.1
    #   totalAmount = totalAmount + countryBudgets['value'].to_f
    # end
    # totalAmount = (format_million_stg totalAmount.to_f).to_s.gsub("&pound;","")
    # totalAmount
  end

  def total_country_budget_location
    firstDayOfFinYear = first_day_of_financial_year(DateTime.now)
    lastDayOfFinYear = last_day_of_financial_year(DateTime.now)
    #oipa 3.1
    totalCountryBudgetLocation = RestClient.get  api_simple_log(settings.oipa_api_url + "budgets/aggregations/?reporting_organisation_identifier=#{settings.goverment_department_ids}&group_by=recipient_country&aggregations=value&budget_period_start=#{firstDayOfFinYear}&budget_period_end=#{lastDayOfFinYear}&format=json&order_by=-value")
    totalCountryBudgetLocation = JSON.parse(totalCountryBudgetLocation)
    totalAmount = 0.0
    totalCountryBudgetLocation['results'].each do |countryBudgets|
      #oipa 2.2
      #totalAmount = totalAmount + countryBudgets['budget'].to_f
      #oipa 3.1
      totalAmount = totalAmount + countryBudgets['value'].to_f
    end
    totalAmount = (format_million_stg totalAmount.to_f).to_s.gsub("&pound;","")
    totalAmount
  end

  def pick_top_six_results(countryCode)
    filteredResults = get_country_results(countryCode);
    top6ResultsTitles = JSON.parse(File.read('data/top6ResultsTitles.json'))
    tempHash = []
    filteredResults.each do |result|
      if(top6ResultsTitles.detect{|title| title["results_indicators"]==result["results_indicators"]})
        tempH = {}
        tempH = top6ResultsTitles.select{|item| item["results_indicators"]==result["results_indicators"]}
        result["title"] = tempH[0]["title"]
        tempHash.push(result)
      end
    end
    tempHash
  end

  def get_country_dept_wise_stats(countryCode)
      countryDeptProjectAPI = RestClient.get  api_simple_log(settings.oipa_api_url + "activities/?format=json&hierarchy=1&recipient_country="+countryCode+"&reporting_org_identifier=#{settings.goverment_department_ids}&fields=activity_status,reporting_organisation,activity_plus_child_aggregation,aggregations&page_size=500")
      countryDeptSectorAPI  = RestClient.get  api_simple_log(settings.oipa_api_url + "budgets/aggregations/?format=json&reporting_org_identifier=#{settings.goverment_department_ids}&activity_status=2&group_by=sector,reporting_organisation&aggregations=value&recipient_country="+countryCode+"&page_size=500")
      countryDeptBudgetAPI  = RestClient.get  api_simple_log(settings.oipa_api_url + "budgets/aggregations/?format=json&reporting_org_identifier=#{settings.goverment_department_ids}&group_by=reporting_organisation,budget_period_start_quarter&aggregations=value&recipient_country="+countryCode+"&order_by=budget_period_start_year,budget_period_start_quarter")

      countryDeptProjectData = JSON.parse(countryDeptProjectAPI)
      deptProjectData = countryDeptProjectData['results']

      countryDeptSectorData = JSON.parse(countryDeptSectorAPI)
      deptSectorData = countryDeptSectorData['results']

      countryDeptBudgetData = JSON.parse(countryDeptBudgetAPI)
      deptBudgetData = countryDeptBudgetData['results']


      ogds = Oj.load(File.read('data/OGDs.json'))

      ####### Department Wise Active & Closed Project Count ###################
      deptProjectData = deptProjectData.select {|project| project['activity_status']!=nil}
      activeProjectDeptWise = deptProjectData.select {|project| project['activity_status']['code']=="2" }.to_a.group_by { |b| b["reporting_organisation"]["narratives"][0]["text"]
      }.map { |dept, bs|
        {
                #{}"id"    => id,
                "dept"  => dept,
                "count" => bs.inject(0) { |v, b| v + 1 },
            }
        }.sort_by{ |k| k["count"]}.reverse
      totalActiveProjectCount=deptProjectData.select {|project| project['activity_status']['code']=="2" }.length
        
      # activeProjectDeptWise.each do |activeProjectDept|
      #   tempOgd = ogds.select{|key, hash| hash["identifiers"].split(",").include?(activeProjectDept["id"])}
      #   tempOgd.each do |o|
      #     #relevantReportingOrgsFinal.push(o[1]["name"])
      #     activeProjectDept["dept"] = o[1]["name"]
      #   end
      # end        

      closeProjectDeptWise = deptProjectData.select {|project| project['activity_status']['code']=="3" || project['activity_status']['code']=="4" }.to_a.group_by { |b| b["reporting_organisation"]["narratives"][0]["text"]
      }.map { |dept, bs|
        {
                #{}"id"    => id,
                "dept"  => dept,
                "count" => bs.inject(0) { |v, b| v + 1 },
            }
        }.sort_by{ |k| k["count"]}.reverse

      totalClosedProjectCount=deptProjectData.select {|project| project['activity_status']['code']=="3" || project['activity_status']['code']=="4" }.length

      budgetSectorDeptList = deptSectorData.select {|sector| sector["value"].to_f!=0 }.to_a.map do |elem| 
        {
                "orgName"                => elem["reporting_organisation"]["primary_name"],
                "sectorId"               => elem["sector"]["code"],
                "higherLevelSectorName"       => "",
                "budget"                 => elem["value"].to_i
        }
      end

      budgetSectorDeptList = get_hash_data_with_high_level_sector_name(budgetSectorDeptList)

      sumBudgetActiveSectorDeptWise = budgetSectorDeptList.group_by { |b| [b["orgName"],b["higherLevelSectorName"]]
      }.map { |orgName, bs|
        {
                "orgName"           => orgName[0],
                "higherLevelSectorName"  => orgName[1],
                "budget"            => bs.inject(0) { |v, b| v + b["budget"] }
            }
        }
        .sort_by{ |k| k["orgName"]}

      sumBudgetActiveSector = sumBudgetActiveSectorDeptWise.group_by  { |b| b["higherLevelSectorName"]
      }.map { |higherLevelSectorName, bs|
        {
                "higherLevelSectorName"  => higherLevelSectorName,
                "budget"             => bs.inject(0) { |v, b| v + b["budget"] }
            }
        }
        .sort_by{ |k| k["budget"]}.reverse

      totalSectorBudget = 0
      sumBudgetActiveSector.each do |sector|
        totalSectorBudget = totalSectorBudget + sector['budget'].to_i
      end  

      distinctHigherSectorAnd5DacSectorIdList = budgetSectorDeptList.group_by { |b| [b["higherLevelSectorName"],b["sectorId"]]
      }.map { |sector, bs|
        {
                "higherLevelSectorName"           => sector[0],
                "5dacSectorId"                    => sector[1]
            }
        }

      count5DacSectorHigherLevelWise = distinctHigherSectorAnd5DacSectorIdList.group_by { |b| b["higherLevelSectorName"]
      }.map { |higherLevelSectorName, bs|
        {
                "higherLevelSectorName"    => higherLevelSectorName,
                "count"                    => bs.inject(0) { |v, b| v + 1 }
            }
        }
        .sort_by{ |k| k["count"]}.reverse  
      
      totalCount5DacSectorHigherLevelWise=0
      count5DacSectorHigherLevelWise.each do |sector|
        totalCount5DacSectorHigherLevelWise = totalCount5DacSectorHigherLevelWise + sector['count'].to_i
      end

      ####### Department Wise Budget Wise Budget ###################

      currentFinancialYear = financial_year
      sumYearWiseDeptBudget = get_actual_budget_per_dept_per_fy(deptBudgetData.select {|year| !year['value'].nil?}).select  {|year| year['fy']>= currentFinancialYear} 


      returnObject = {
            :activeProjectDeptWise         => activeProjectDeptWise,
            :totalActiveProjectCount       => totalActiveProjectCount,
            :closeProjectDeptWise          => closeProjectDeptWise,
            :totalClosedProjectCount       => totalClosedProjectCount,
            :sumBudgetActiveSector         => sumBudgetActiveSector,
            :totalSectorBudget             => totalSectorBudget, 
            :sumBudgetActiveSectorDeptWise => sumBudgetActiveSectorDeptWise,
            :count5DacSectorHigherLevelWise=> count5DacSectorHigherLevelWise,
            :totalCount5DacSectorHigherLevelWise => totalCount5DacSectorHigherLevelWise,
            :sumYearWiseDeptBudget         => sumYearWiseDeptBudget  
            }  
  end

  def location_data_for_countries_csv(countryCode)
        oipa = RestClient.get  api_simple_log(settings.oipa_api_url + "activities/?format=json&reporting_org_identifier=#{settings.goverment_department_ids}&hierarchy=1&recipient_country=#{countryCode}&fields=title,location&page_size=500&activity_status=2")
        projects = JSON.parse(oipa)
        locationArray = Array.new
        projects['results'].each do |project|
          project['location'].each do |location|
              locationHash = {}
              begin
                  locationHash['IATI Identifier'] = location['iati_identifier']
              rescue
                  locationHash['IATI Identifier'] = 'N/A'
              end
              begin
                  locationHash['Activity Title'] = project['title']['narrative'][0]['text']
              rescue
                  locationHash['Activity Title'] = 'N/A'
              end
              begin
                 locationHash['Location Reach'] = location['location_reach']['code'] 
              rescue
                  locationHash['Location Reach'] = 'N/A'
              end
              begin
                 locationHash['Location Name'] = location['name']['narrative'][0]['text'] 
              rescue
                  locationHash['Location Name'] = 'N/A'
              end
              begin
                  locationHash['Location Description'] = location['description']['narrative'][0]['text']
              rescue
                  locationHash['Location Description'] = 'N/A'
              end
              begin
                  locationHash['Administrative Vocabulary'] = location['administrative'][0]['code']
              rescue
                  locationHash['Administrative Vocabulary'] = 'N/A'
              end
              begin
                  locationHash['Latitude'] = location['point']['pos']['latitude']
              rescue
                  locationHash['Latitude'] = 'N/A'
              end
              begin
                  locationHash['Longitude'] = location['point']['pos']['longitude']
              rescue
                  locationHash['Longitude'] = 'N/A'
              end
              begin
                  locationHash['Exactness'] = location['exactness']['code']
              rescue
                  locationHash['Exactness'] = 'N/A'
              end
              begin
                  locationHash['Location Class'] = location['location_class']['code']
              rescue
                  locationHash['Location Class'] = 'N/A'
              end
              begin
                  locationHash['Feature Designation'] = location['feature_designation']['code']
              rescue
                  locationHash['Feature Designation'] = 'N/A'
              end
              locationArray.push(locationHash)
          end  
        end
        if locationArray.length > 0
            locationData = hash_to_csv(locationArray)
        else
            locationData = ''
        end
        locationData
    end

    #Get a list of map markers for visualisation
    def getCountryMapMarkers(countryCode)
      # https://fcdo-direct-indexing.iati.cloud/search/activity?q=reporting_org_ref:(GB-GOV-1 GB-1) AND recipient_country_code:BD AND activity_status_code:2 AND hierarchy:1&rows=500&fl=recipient_country_code,recipient_country_name,recipient_country_percentage,recipient_country_narrative_lang,recipient_country_narrative_text,recipient_region_code,recipient_region_name,recipient_region_vocabulary,recipient_region_percentage,recipient_region_narrative_lang,recipient_region_narrative_text,title_narrative_first,title_narrative_lang,title_narrative_text,iati_identifier,location_ref,location_reach_code,location_id_vocabulary,location_id_code,location_point_pos,location_exactness_code,location_class_code,location_feature_designation_code,location_name_narrative_text,location_name_narrative_lang,location_description_narrative_text,location_description_narrative_lang,location_activity_description_narrative_text,location_activity_description_narrative_lang,location_administrative_vocabulary,location_administrative_level,location_administrative_code
      #puts settings.oipa_api_url_other + 'xxxactivity?q=reporting_org_ref:('+settings.goverment_department_ids.gsub(","," OR ")+') AND recipient_country_code:#{countryCode} AND activity_status_code:2 AND hierarchy:1&rows=500&fl=recipient_country_code,recipient_country_name,recipient_country_percentage,recipient_country_narrative_lang,recipient_country_narrative_text,recipient_region_code,recipient_region_name,recipient_region_vocabulary,recipient_region_percentage,recipient_region_narrative_lang,recipient_region_narrative_text,title_narrative_first,title_narrative_lang,title_narrative_text,iati_identifier,location_ref,location_reach_code,location_id_vocabulary,location_id_code,location_point_pos,location_exactness_code,location_class_code,location_feature_designation_code,location_name_narrative_text,location_name_narrative_lang,location_description_narrative_text,location_description_narrative_lang,location_activity_description_narrative_text,location_activity_description_narrative_lang,location_administrative_vocabulary,location_administrative_level,location_administrative_code'
      newRawMapMakers = JSON.parse(RestClient.get  api_simple_log(settings.oipa_api_url_other + 'activity?q=reporting_org_ref:('+settings.goverment_department_ids.gsub(","," OR ")+') AND recipient_country_code:'+countryCode+' AND activity_status_code:2 AND hierarchy:1&rows=500&fl=recipient_country_code,recipient_country_name,recipient_country_percentage,recipient_country_narrative_lang,recipient_country_narrative_text,recipient_region_code,recipient_region_name,recipient_region_vocabulary,recipient_region_percentage,recipient_region_narrative_lang,recipient_region_narrative_text,title_narrative_first,title_narrative_lang,title_narrative_text,iati_identifier,location_ref,location_reach_code,location_id_vocabulary,location_id_code,location_point_pos,location_exactness_code,location_class_code,location_feature_designation_code,location_name_narrative_text,location_name_narrative_lang,location_description_narrative_text,location_description_narrative_lang,location_activity_description_narrative_text,location_activity_description_narrative_lang,location_administrative_vocabulary,location_administrative_level,location_administrative_code'))
      newRawMapMakers = newRawMapMakers['response']['docs']
      # rawMapMarkers = JSON.parse(RestClient.get  api_simple_log(settings.oipa_api_url + "activities/?format=json&reporting_org_identifier=#{settings.goverment_department_ids}&hierarchy=1&recipient_country=#{countryCode}&fields=recipient_country,recipient_region,title,iati_identifier,location&page_size=500&activity_status=2"))
      # rawMapMarkers = rawMapMarkers['results']
      mapMarkers = Array.new
      ar = 0
      newRawMapMakers.each do |data|
        if data.has_key?('location_point_pos')
          data['location_point_pos'].each_with_index do | element, index |
            tempStorage = {}
            tempStorage["geometry"] = {}
            tempStorage['geometry']['type'] = 'Point'
            tempStorage['geometry']['coordinates'] = Array.new
            tempStorage['geometry']['coordinates'].push(element.split[1].to_f)
            tempStorage['geometry']['coordinates'].push(element.split[0].to_f)
            tempStorage['iati_identifier'] = data['iati_identifier']
            begin
              tempStorage['loc'] = data['location_name_narrative_text'][index]
            rescue
              tempStorage['loc'] = 'N/A'
            end
            begin
              tempStorage['title'] = data['title_narrative_text'].first
            rescue
              tempStorage['title'] = 'N/A'
            end
            mapMarkers.push(tempStorage)
            ar = ar + 1
          end
        end
      end
      # rawMapMarkers.each do |data|
      #   if(data['recipient_country'].count == 1)
      #     data['location'].each do |location|
      #       begin
      #         tempStorage = {}
      #         tempStorage["geometry"] = {}
      #         tempStorage['geometry']['type'] = 'Point'
      #         tempStorage['geometry']['coordinates'] = Array.new
      #         tempStorage['geometry']['coordinates'].push(location['point']['pos']['longitude'].to_f)
      #         tempStorage['geometry']['coordinates'].push(location['point']['pos']['latitude'].to_f)
      #         tempStorage['iati_identifier'] = location['iati_identifier']
      #         begin
      #           tempStorage['loc'] = location['name']['narrative'][0]['text']
      #         rescue
      #           tempStorage['loc'] = 'N/A'
      #         end
      #         begin
      #           tempStorage['title'] = data['title']['narrative'][0]['text']
      #         rescue
      #           tempStorage['title'] = 'N/A'
      #         end
      #         mapMarkers.push(tempStorage)
      #         ar = ar + 1
      #       rescue
      #         puts 'Data missing in API response.'
      #       end
      #     end
      #   end
      # end
      mapMarkers
    end

    # Get country bounds for map visualisation
    def getCountryBounds(countryCode)
      countryMappedFile = JSON.parse(File.read('data/country_ISO3166_mapping.json'))
      country3DigitCode = ''
      if countryMappedFile.has_key?(countryCode)
        country3DigitCode = countryMappedFile[countryCode]
      end
      geoLocationData = ''
      geoJsonData = ''
      if country3DigitCode != ''
        geoLocationData = JSON.parse(File.read('data/world.json'))
        geoLocationData['features'].each do |loc|
          if loc['properties']['ISO_A3'].to_s == country3DigitCode.to_s
            geoJsonData = loc['geometry']
            break;
          end
        end
      end
      geoJsonData
    end
    
  # Returns the country level implementing organisations
  def getCountryLevelImplOrgs(countryCode, activityCount)
    implementingOrgs = {}
    newtempActivityCount = 'activity?q=reporting_org_ref:('+settings.goverment_department_ids.gsub(","," OR ")+') AND recipient_country_code:('+countryCode+') AND activity_status_code:2 AND hierarchy:1 AND participating_org_role:4&fl=participating_org_role,participating_org_narrative,participating_org_ref&rows=10000'
    newAPIResponse = Oj.load(RestClient.get  api_simple_log(settings.oipa_api_url_other + newtempActivityCount))['response']['docs']
    newAPIResponse.each do |activity|
      activity['participating_org_role'].each_with_index do | element, index |
        if (element.to_i == 4 && activity['participating_org_ref'][index] != '')
          if(implementingOrgs.has_key?(activity['participating_org_ref'][index]))
            implementingOrgs[activity['participating_org_ref'][index]]['count'] = implementingOrgs[activity['participating_org_ref'][index]]['count'] + 1
          else
            implementingOrgs[activity['participating_org_ref'][index]] = {}
            implementingOrgs[activity['participating_org_ref'][index]]['orgName'] = activity['participating_org_narrative'][index]
            implementingOrgs[activity['participating_org_ref'][index]]['count'] = 1
          end
        end
      end
    end
    implementingOrgs
  end
end