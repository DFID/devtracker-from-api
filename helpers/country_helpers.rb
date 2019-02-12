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
      puts settings.goverment_department_ids
      #top5countriesJSON = RestClient.get settings.oipa_api_url + "budgets/aggregations/?reporting_organisation=GB-GOV-1&group_by=recipient_country&aggregations=value&budget_period_start=#{firstDayOfFinYear}&budget_period_end=#{lastDayOfFinYear}&order_by=-value&page_size=10&format=json"
      top5countriesJSON = RestClient.get settings.oipa_api_url + "budgets/aggregations/?reporting_organisation_identifier=#{settings.goverment_department_ids}&group_by=recipient_country&aggregations=value&budget_period_start=#{firstDayOfFinYear}&budget_period_end=#{lastDayOfFinYear}&order_by=-value&page_size=10&format=json"
      top5countries = JSON.parse(top5countriesJSON)

      top5countriesBudget = top5countries["results"].map do |elem| 
         {  
            :code     => elem["recipient_country"]["code"],  
            :name     => countriesInfo.find do |source|
                           source["code"].to_s == elem["recipient_country"]["code"]
                         end["name"],
            :budget   => elem["value"]                                                                                    
         } 
      end
  end

  def get_country_code_name(countryCode)
      countriesInfo = Oj.load(File.read('data/countries.json'))
      country = countriesInfo.select {|country| country['code'] == countryCode}.first
      returnObject = {
            :code => country['code'],
            :name => country['name']
            }
  end

  def get_country_details(countryCode)

      firstDayOfFinYear = first_day_of_financial_year(DateTime.now)
      lastDayOfFinYear = last_day_of_financial_year(DateTime.now)
      
      countriesInfo = Oj.load(File.read('data/countries.json'))
      country = countriesInfo.select {|country| country['code'] == countryCode}.first
      
      countryOperationalBudgetInfo = Oj.load(File.read('data/countries_operational_budgets.json'))
      countryOperationalBudget = countryOperationalBudgetInfo.select {|result| result['code'] == countryCode}
      
      #oipa v2.2
      #currentTotalCountryBudget= get_current_total_budget(RestClient.get settings.oipa_api_url + "activities/aggregations/?format=json&reporting_organisation=GB-GOV-1&budget_period_start=#{firstDayOfFinYear}&budget_period_end=#{lastDayOfFinYear}&group_by=recipient_country&aggregations=budget&recipient_country=#{countryCode}")
      #currentTotalDFIDBudget = get_current_dfid_total_budget(RestClient.get settings.oipa_api_url + "activities/aggregations/?format=json&reporting_organisation=GB-GOV-1&budget_period_start=#{firstDayOfFinYear}&budget_period_end=#{lastDayOfFinYear}&group_by=reporting_organisation&aggregations=budget")
      #oipa v3.1
      currentTotalCountryBudget= get_current_total_budget(RestClient.get settings.oipa_api_url + "budgets/aggregations/?format=json&reporting_organisation_identifier=#{settings.goverment_department_ids}&budget_period_start=#{firstDayOfFinYear}&budget_period_end=#{lastDayOfFinYear}&group_by=recipient_country&aggregations=value&recipient_country=#{countryCode}")
      currentTotalDFIDBudget = get_current_dfid_total_budget(RestClient.get settings.oipa_api_url + "budgets/aggregations/?format=json&reporting_organisation_identifier=#{settings.goverment_department_ids}&budget_period_start=#{firstDayOfFinYear}&budget_period_end=#{lastDayOfFinYear}&group_by=reporting_organisation&aggregations=value")

      totalProjectsDetails = get_total_project(RestClient.get settings.oipa_api_url + "activities/?reporting_organisation_identifier=#{settings.goverment_department_ids}&hierarchy=1&recipient_country=#{countryCode}&format=json&fields=activity_status&page_size=250&activity_status=2")
      totalActiveProjects = totalProjectsDetails['results'].select {|status| status['activity_status']['code'] =="2" }.length

      if countryOperationalBudget.length > 0 then
          operationalBudget = countryOperationalBudget[0]['operationalBudget']
          operationalBudgetCurrency = countryOperationalBudget[0]['currency']
      else
          operationalBudget = 0 
          operationalBudgetCurrency = "GBP"
      end

      if currentTotalCountryBudget['count'] > 0 then
          #oipa v2.2
          #countryBudget = currentTotalCountryBudget['results'][0]['budget']
          #oipa v3.1
          countryBudget = currentTotalCountryBudget['results'][0]['value']
      else
          countryBudget = 0
      end

      #oipa v2.2
      #totalDfidBudget = currentTotalDFIDBudget['results'][0]['budget']
      #oipa v3.1
      totalDfidBudget = 0
      currentTotalDFIDBudget['results'].each do |budget|
        totalDfidBudget = totalDfidBudget + budget['value'].to_i
      end
      #totalDfidBudget = currentTotalDFIDBudget['results'][0]['value']
      projectBudgetPercentToDfidBudget = ((countryBudget.round(2) / totalDfidBudget.round(2))*100).round(2)

    
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
            :totalProjects => totalProjectsDetails['count'],
            :totalActiveProjects => totalActiveProjects,
            :operationalBudget => operationalBudget,
            :operationalBudgetCurrency => operationalBudgetCurrency,
            :countryBudget => countryBudget,
            :countryBudgetCurrency => "GBP",
            :projectBudgetPercentToDfidBudget => projectBudgetPercentToDfidBudget
            }
  end

  

  def get_country_results(countryCode)
      resultsInfo = Oj.load(File.read('data/results.json'))
      results = resultsInfo.select {|result| result['code'] == countryCode}
  end


  def get_country_or_region(projectId)
      #get the data
      if is_dfid_project(projectId) then
         countryOrRegionAPI = RestClient.get settings.oipa_api_url + "activities/?related_activity_id=#{projectId}&fields=iati_identifier,recipient_countries,recipient_regions&hierarchy=2&format=json&page_size=500"
      else
         countryOrRegionAPI = RestClient.get settings.oipa_api_url + "activities/?id=#{projectId}&fields=iati_identifier,recipient_countries,recipient_regions&format=json&page_size=500"
      end   
      
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

  def get_country_region_yearwise_budget_graph_data(apiLink)

      yearWiseBudgets = Oj.load(apiLink)
      #oipa v2.2
      #yearWiseBudgets['results'] = yearWiseBudgets['results'].select {|project| !project['budget'].nil?}
      #oipa v3.1
      yearWiseBudgets['results'] = yearWiseBudgets['results'].select {|project| !project['value'].nil?}
      budgetYearData = financial_year_wise_budgets(yearWiseBudgets['results'],"C")

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

  def get_country_all_projects_rss(countryCode)
    rssJSON = RestClient.get settings.oipa_api_url + "activities/?format=json&reporting_organisation_identifier=#{settings.goverment_department_ids}&hierarchy=1&related_activity_recipient_country=#{countryCode}&ordering=-last_updated_datetime&fields=last_updated_datetime,title,descriptions,iati_identifier&page_size=500"
    rssData = JSON.parse(rssJSON)
    rssResults = rssData['results']
  end
  
  def total_country_budget_location
    firstDayOfFinYear = first_day_of_financial_year(DateTime.now)
    lastDayOfFinYear = last_day_of_financial_year(DateTime.now)
    #oipa 2.2
    #totalCountryBudgetLocation = RestClient.get settings.oipa_api_url + "activities/aggregations/?reporting_organisation=GB-GOV-1&group_by=recipient_country&aggregations=budget&budget_period_start=#{firstDayOfFinYear}&budget_period_end=#{lastDayOfFinYear}&order_by=-budget&format=json"
    #oipa 3.1
    totalCountryBudgetLocation = RestClient.get settings.oipa_api_url + "budgets/aggregations/?reporting_organisation_identifier=GB-GOV-1&group_by=recipient_country&aggregations=value&budget_period_start=#{firstDayOfFinYear}&budget_period_end=#{lastDayOfFinYear}&format=json&order_by=-value"
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
      countryDeptProjectAPI = RestClient.get settings.oipa_api_url + "activities/?format=json&hierarchy=1&recipient_country="+countryCode+"&reporting_organisation_identifier=#{settings.goverment_department_ids}&fields=activity_status,reporting_organisations,activity_plus_child_aggregation,aggregations&page_size=500"
      countryDeptSectorAPI  = RestClient.get settings.oipa_api_url + "budgets/aggregations/?format=json&reporting_organisation_identifier=#{settings.goverment_department_ids}&activity_status=2&group_by=sector,reporting_organisation&aggregations=value&recipient_country="+countryCode+"&page_size=500"
      countryDeptBudgetAPI  = RestClient.get settings.oipa_api_url + "budgets/aggregations/?format=json&reporting_organisation_identifier=#{settings.goverment_department_ids}&group_by=reporting_organisation,budget_period_start_quarter&aggregations=value&recipient_country="+countryCode+"&order_by=budget_period_start_year,budget_period_start_quarter"

      countryDeptProjectData = JSON.parse(countryDeptProjectAPI)
      deptProjectData = countryDeptProjectData['results']

      countryDeptSectorData = JSON.parse(countryDeptSectorAPI)
      deptSectorData = countryDeptSectorData['results']

      countryDeptBudgetData = JSON.parse(countryDeptBudgetAPI)
      deptBudgetData = countryDeptBudgetData['results']


      ogds = Oj.load(File.read('data/OGDs.json'))

      ####### Department Wise Active & Closed Project Count ###################
      deptProjectData = deptProjectData.select {|project| project['activity_status']!=nil}
      activeProjectDeptWise = deptProjectData.select {|project| project['activity_status']['code']=="2" }.to_a.group_by { |b| b["reporting_organisations"][0]["narratives"][0]["text"]
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

      closeProjectDeptWise = deptProjectData.select {|project| project['activity_status']['code']=="3" || project['activity_status']['code']=="4" }.to_a.group_by { |b| b["reporting_organisations"][0]["narratives"][0]["text"]
      }.map { |dept, bs|
        {
                #{}"id"    => id,
                "dept"  => dept,
                "count" => bs.inject(0) { |v, b| v + 1 },
            }
        }.sort_by{ |k| k["count"]}.reverse

      totalClosedProjectCount=deptProjectData.select {|project| project['activity_status']['code']=="3" || project['activity_status']['code']=="4" }.length

      # closeProjectDeptWise.each do |closeProjectDept|
      #   tempOgd = ogds.select{|key, hash| hash["identifiers"].split(",").include?(closeProjectDept["id"])}
      #   tempOgd.each do |o|
      #     #relevantReportingOrgsFinal.push(o[1]["name"])
      #     closeProjectDept["dept"] = o[1]["name"]
      #   end
      # end

      ####### Department Wise Sector Wise Budget ###################

      #highLevelSectorListData = high_level_sector_list( RestClient.get settings.oipa_api_url + "budgets/aggregations/?format=json&reporting_organisation=#{settings.goverment_department_ids}&activity_status=2&group_by=sector,reporting_organisation&aggregations=value&recipient_country="+countryCode+"", "all_sectors", "High Level Code (L1)", "High Level Sector Description")    
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
end