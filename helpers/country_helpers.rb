module CountryHelpers

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

  def get_country_code_name(countryCode)
      countriesInfo = JSON.parse(File.read('data/countries.json'))
      country = countriesInfo.select {|country| country['code'] == countryCode}.first
      returnObject = {
            :code => country['code'],
            :name => country['name']
            }

  end

  def get_country_details(countryCode)

      firstDayOfFinYear = first_day_of_financial_year(DateTime.now)
      lastDayOfFinYear = last_day_of_financial_year(DateTime.now)
      
      countriesInfo = JSON.parse(File.read('data/countries.json'))
      country = countriesInfo.select {|country| country['code'] == countryCode}.first
      
      countryOperationalBudgetInfo = JSON.parse(File.read('data/countries_operational_budgets.json'))
      countryOperationalBudget = countryOperationalBudgetInfo.select {|result| result['code'] == countryCode}
      
      oipaCurrentTotalCountryBudget = RestClient.get settings.oipa_api_url + "activities/aggregations?format=json&reporting_organisation=GB-1&budget_period_start=#{firstDayOfFinYear}&budget_period_end=#{lastDayOfFinYear}&group_by=recipient_country&aggregations=budget&recipient_country=#{countryCode}" 
      currentTotalCountryBudget= JSON.parse_nil(oipaCurrentTotalCountryBudget)
      
      oipaCurrentTotalDFIDBudget = RestClient.get settings.oipa_api_url + "activities/aggregations?format=json&reporting_organisation=GB-1&budget_period_start=#{firstDayOfFinYear}&budget_period_end=#{lastDayOfFinYear}&group_by=reporting_organisation&aggregations=budget"
      currentTotalDFIDBudget = JSON.parse(oipaCurrentTotalDFIDBudget)

      totalProjectsDetails = get_country_total_project(countryCode)
      totalActiveProjects = totalProjectsDetails['results'].select {|status| status['activity_status']['code'] =="2" }.length

      if countryOperationalBudget.length > 0 then
          operationalBudget = countryOperationalBudget[0]['operationalBudget']
          operationalBudgetCurrency = countryOperationalBudget[0]['currency']
      else
          operationalBudget = 0 
          operationalBudgetCurrency = "GBP"
      end

      if currentTotalCountryBudget['count'] > 0 then
          countryBudget = currentTotalCountryBudget['results'][0]['budget']
      else
          countryBudget = 0
      end

      totalDfidBudget = currentTotalDFIDBudget['results'][0]['budget']
      
      projectBudgetPercentToDfidBudget = ((countryBudget.round(2) / totalDfidBudget.round(2))*100).round(2)

    
      returnObject = {
            :code => country['code'],
            :name => country['name'],
            :description => country['description'],
            :population => country['population'],
            :lifeExpectancy => country['lifeExpectancy'],
            :incomeLevel => country['incomeLevel'],
            :belowPovertyLine => country['belowPovertyLine'],
            :fertilityRate => country['fertilityRate'],
            :gdpGrowthRate => country['gdpGrowthRate'],
            :totalProjects => totalProjectsDetails['count'],
            :totalActiveProjects => totalActiveProjects,
            :operationalBudget => operationalBudget,
            :operationalBudgetCurrency => operationalBudgetCurrency,
            :countryBudget => countryBudget,
            :countryBudgetCurrency => "GBP",
            :projectBudgetPercentToDfidBudget => projectBudgetPercentToDfidBudget
            }
  end

  def get_country_total_project(countryCode)
      oipaCountryTotalProjects = RestClient.get settings.oipa_api_url + "activities?reporting_organisation=GB-1&hierarchy=1&related_activity_recipient_country=#{countryCode}&format=json&fields=activity_status&page_size=150"
      totalProjects = JSON.parse(oipaCountryTotalProjects)
  end

  def get_country_results(countryCode)
      resultsInfo = JSON.parse(File.read('data/results.json'))
      results = resultsInfo.select {|result| result['code'] == countryCode}
  end


  def get_country_or_region(projectId)
      #get the data
      countryOrRegionAPI = RestClient.get settings.oipa_api_url + "activities?related_activity_id=#{projectId}&fields=iati_identifier,recipient_countries,recipient_regions&hierarchy=2&format=json"
      countryOrRegionData = JSON.parse(countryOrRegionAPI)
      data = countryOrRegionData['results']

      #iterate through the array
      countries = data.collect{ |activity| activity['recipient_countries'][0]}.uniq.compact
      regions = data.collect{ |activity| activity['recipient_regions'][0]}.uniq.compact

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
        globalLabel << c['country']['name']
      end
      regions.map do |r|
        globalLabel << r['region']['name']
      end
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

  def get_country_yearwise_budget_graph_data(countryCode)
      oipaYearWiseBudgets = RestClient.get settings.oipa_api_url + "activities/aggregations?format=json&reporting_organisation=GB-1&group_by=budget_per_quarter&aggregations=budget&recipient_country=#{countryCode}&order_by=year,quarter"
      yearWiseBudgets = JSON.parse_nil(oipaYearWiseBudgets)

      budgetYearData = financial_year_wise_budgets(yearWiseBudgets['results'],"C")

  end
  
  def get_country_sector_graph_data(countrySpecificsectorValuesJSONLink)
      budgetArray = Array.new
      resultCount = JSON.parse(countrySpecificsectorValuesJSONLink)
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
  
end