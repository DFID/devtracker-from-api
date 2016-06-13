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

      top5countriesJSON = RestClient.get settings.oipa_api_url + "activities/aggregations/?reporting_organisation=GB-GOV-1&group_by=recipient_country&aggregations=budget&budget_period_start=#{firstDayOfFinYear}&budget_period_end=#{lastDayOfFinYear}&order_by=-budget&page_size=5&format=json"
      top5countries = JSON.parse(top5countriesJSON)

      top5countriesBudget = top5countries["results"].map do |elem| 
         {  
            :code     => elem["recipient_country"]["code"],  
            :name     => countriesInfo.find do |source|
                           source["code"].to_s == elem["recipient_country"]["code"]
                         end["name"],
            :budget   => elem["budget"]                                                                                    
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
      
      currentTotalCountryBudget= get_current_total_budget(RestClient.get settings.oipa_api_url + "activities/aggregations/?format=json&reporting_organisation=GB-GOV-1&budget_period_start=#{firstDayOfFinYear}&budget_period_end=#{lastDayOfFinYear}&group_by=recipient_country&aggregations=budget&recipient_country=#{countryCode}")
      currentTotalDFIDBudget = get_current_dfid_total_budget(RestClient.get settings.oipa_api_url + "activities/aggregations/?format=json&reporting_organisation=GB-GOV-1&budget_period_start=#{firstDayOfFinYear}&budget_period_end=#{lastDayOfFinYear}&group_by=reporting_organisation&aggregations=budget")

      totalProjectsDetails = get_total_project(RestClient.get settings.oipa_api_url + "activities/?reporting_organisation=GB-GOV-1&hierarchy=1&related_activity_recipient_country=#{countryCode}&format=json&fields=activity_status&page_size=250&activity_status=2")
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

  

  def get_country_results(countryCode)
      resultsInfo = Oj.load(File.read('data/results.json'))
      results = resultsInfo.select {|result| result['code'] == countryCode}
  end


  def get_country_or_region(projectId)
      #get the data
      if is_dfid_project(projectId) then
         countryOrRegionAPI = RestClient.get settings.oipa_api_url + "activities/?related_activity_id=#{projectId}&fields=iati_identifier,recipient_countries,recipient_regions&hierarchy=2&format=json"
      else
         countryOrRegionAPI = RestClient.get settings.oipa_api_url + "activities/?id=#{projectId}&fields=iati_identifier,recipient_countries,recipient_regions&format=json"
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
      yearWiseBudgets['results'] = yearWiseBudgets['results'].select {|project| !project['budget'].nil?}
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
  
  def get_country_all_projects_data(countryCode)
    allProjectsData = {}
    allProjectsData['countryAllProjectFilters'] = get_static_filter_list()
    allProjectsData['country'] = get_country_code_name(countryCode)
    allProjectsData['results'] = get_country_results(countryCode)
    #oipa_project_list_count = RestClient.get settings.oipa_api_url + "activities/?hierarchy=1&format=json&reporting_organisation=GB-GOV-1&page_size=10&fields=descriptions,activity_status,iati_identifier,url,title,reporting_organisations,activity_plus_child_aggregation,aggregations&activity_status=1,2,3,4,5&ordering=-activity_plus_child_budget_value&related_activity_recipient_country=#{countryCode}"
    #allProjectsData['projectsCount']= JSON.parse(oipa_project_list_count)

    oipa_project_list = RestClient.get settings.oipa_api_url + "activities/?hierarchy=1&format=json&reporting_organisation=GB-GOV-1&page_size=10&fields=descriptions,activity_status,iati_identifier,url,title,reporting_organisations,activity_plus_child_aggregation,aggregations&activity_status=2&ordering=-activity_plus_child_budget_value&related_activity_recipient_country=#{countryCode}"
    allProjectsData['projects']= JSON.parse(oipa_project_list)
    sectorValuesJSON = RestClient.get settings.oipa_api_url + "activities/aggregations/?format=json&group_by=sector&aggregations=count&reporting_organisation=GB-GOV-1&related_activity_recipient_country=#{countryCode}&activity_status=2"
    allProjectsData['highLevelSectorList'] = high_level_sector_list_filter(sectorValuesJSON)
    #projects = projects_list['results']
    allProjectsData['project_budget_higher_bound'] = 0
    allProjectsData['actualStartDate'] = '1990-01-01T00:00:00' 
    allProjectsData['plannedEndDate'] = '2000-01-01T00:00:00'
    unless allProjectsData['projects']['results'][0].nil?
      allProjectsData['project_budget_higher_bound'] = allProjectsData['projects']['results'][0]['aggregations']['activity_children']['budget_value']
    end
    allProjectsData['actualStartDate'] = RestClient.get settings.oipa_api_url + "activities?format=json&page_size=1&fields=activity_dates&reporting_organisation=GB-GOV-1&hierarchy=1&related_activity_recipient_country=#{countryCode}&ordering=actual_start_date&start_date_gte=1900-01-02&activity_status=2"
    allProjectsData['actualStartDate'] = JSON.parse(allProjectsData['actualStartDate'])
    tempStartDate = allProjectsData['actualStartDate']['results'][0]['activity_dates'].select{|activityDate| activityDate['type']['code'] == '2'}.first
    if (tempStartDate.nil?)
      tempStartDate = allProjectsData['actualStartDate']['results'][0]['activity_dates'].select{|activityDate| activityDate['type']['code'] == '1'}.first
    end
    allProjectsData['actualStartDate'] = tempStartDate
    allProjectsData['actualStartDate'] = allProjectsData['actualStartDate']['iso_date']

    #unless allProjectsData['actualStartDate']['results'][0].nil? 
    #  allProjectsData['actualStartDate'] = allProjectsData['actualStartDate']['results'][0]['activity_dates'][1]['iso_date']
    #end
    allProjectsData['plannedEndDate'] = RestClient.get settings.oipa_api_url + "activities?format=json&page_size=1&fields=activity_dates&reporting_organisation=GB-GOV-1&hierarchy=1&related_activity_recipient_country=#{countryCode}&ordering=-planned_end_date&end_date_isnull=False&activity_status=2"
    allProjectsData['plannedEndDate'] = JSON.parse(allProjectsData['plannedEndDate'])
    allProjectsData['plannedEndDate'] = allProjectsData['plannedEndDate']['results'][0]['activity_dates'].select{|activityDate| activityDate['type']['code'] == '3'}.first
    allProjectsData['plannedEndDate'] = allProjectsData['plannedEndDate']['iso_date']
    #unless allProjectsData['plannedEndDate']['results'][0].nil?
    #  allProjectsData['plannedEndDate'] = allProjectsData['plannedEndDate']['results'][0]['activity_dates'][2]['iso_date']
    #end
    oipa_document_type_list = RestClient.get settings.oipa_api_url + "activities/aggregations/?format=json&group_by=document_link_category&aggregations=count&reporting_organisation=GB-GOV-1&related_activity_recipient_country=#{countryCode}&activity_status=2"
    document_type_list = JSON.parse(oipa_document_type_list)
    allProjectsData['document_types'] = document_type_list['results']

    #Implementing org type filters
    participatingOrgInfo = JSON.parse(File.read('data/participatingOrgList.json'))
    oipa_implementingOrg_type_list = RestClient.get settings.oipa_api_url + "activities/aggregations/?format=json&group_by=participating_organisation&aggregations=count&reporting_organisation=GB-GOV-1&related_activity_recipient_country=#{countryCode}&hierarchy=1&activity_status=2"
    implementingOrg_type_list = JSON.parse(oipa_implementingOrg_type_list)
    allProjectsData['implementingOrg_types'] = implementingOrg_type_list['results']
    allProjectsData['implementingOrg_types'].each do |implementingOrgs|
      if implementingOrgs['name'].length < 1
        tempImplmentingOrgData = participatingOrgInfo.select{|implementingOrg| implementingOrg['Code'].to_s == implementingOrgs['ref'].to_s}.first
        if tempImplmentingOrgData.nil?
          implementingOrgs['ref'] = 'na'
          implementingOrgs['name'] = 'na'
        else
          implementingOrgs['name'] = tempImplmentingOrgData['Name']
        end
      end
    end
    allProjectsData['highLevelSectorList'] = allProjectsData['highLevelSectorList'].sort_by {|key| key}
    allProjectsData['document_types'] = allProjectsData['document_types'].sort_by {|key| key["document_link_category"]["name"]}
    allProjectsData['implementingOrg_types'] = allProjectsData['implementingOrg_types'].sort_by {|key| key["name"]}.uniq {|key| key["ref"]}
    return allProjectsData
  end

  def get_country_all_projects_data_para(countryCode)
    allProjectsData = {}
    apiLinks = [{"title"=>"oipa_project_list", "link"=>"activities/?hierarchy=1&format=json&reporting_organisation=GB-GOV-1&page_size=10&fields=descriptions,activity_status,iati_identifier,url,title,reporting_organisations,activity_plus_child_aggregation,aggregations&activity_status=2&ordering=-activity_plus_child_budget_value&related_activity_recipient_country=#{countryCode}"},{"title"=>"sectorValuesJSON", "link"=>"activities/aggregations/?format=json&group_by=sector&aggregations=count&reporting_organisation=GB-GOV-1&related_activity_recipient_country=#{countryCode}"},{"title"=>"actualStartDate", "link"=>"activities/?format=json&page_size=1&fields=activity_dates&reporting_organisation=GB-GOV-1&hierarchy=1&related_activity_recipient_country=#{countryCode}&ordering=actual_start_date"},{"title"=>"plannedEndDate", "link"=>"activities/?format=json&page_size=1&fields=activity_dates&reporting_organisation=GB-GOV-1&hierarchy=1&related_activity_recipient_country=#{countryCode}&ordering=-planned_end_date"}]
    returnedAPIData = ""
    EM.synchrony do
      concurrency = 4
      urls = [settings.oipa_api_url + apiLinks[0]["link"], settings.oipa_api_url + apiLinks[1]["link"], settings.oipa_api_url + apiLinks[2]["link"], settings.oipa_api_url + apiLinks[3]["link"]]
      returnedAPIData = EM::Synchrony::Iterator.new(urls, concurrency).map do |url, iter|
          http = EventMachine::HttpRequest.new(url, :connect_timeout => 50).aget
          http.callback { iter.return(http) }
          http.errback { iter.return(http) }
      end
      EventMachine.stop
    end
    puts returnedAPIData[1].response
    allProjectsData['countryAllProjectFilters'] = get_static_filter_list()
    allProjectsData['country'] = get_country_code_name(countryCode)
    allProjectsData['results'] = get_country_results(countryCode)
    allProjectsData['projects']= Oj.load(returnedAPIData[0].response)

    allProjectsData['highLevelSectorList'] = high_level_sector_list_filter(returnedAPIData[1].response)
    allProjectsData['project_budget_higher_bound'] = 0
    allProjectsData['actualStartDate'] = '1990-01-01T00:00:00' 
    allProjectsData['plannedEndDate'] = '2000-01-01T00:00:00'
    unless allProjectsData['projects']['results'][0].nil?
      allProjectsData['project_budget_higher_bound'] = allProjectsData['projects']['results'][0]['activity_plus_child_aggregation']['budget_value']
    end
    ###allProjectsData['actualStartDate'] = Oj.load(returnedAPIData[2].response)
    ###unless allProjectsData['actualStartDate']['results'][0].nil? 
      ###allProjectsData['actualStartDate'] = allProjectsData['actualStartDate']['results'][0]['activity_dates'][1]['iso_date']
    ###end
    ###allProjectsData['plannedEndDate'] = Oj.load(returnedAPIData[3].response)
    ###unless allProjectsData['plannedEndDate']['results'][0].nil?
      ###allProjectsData['plannedEndDate'] = allProjectsData['plannedEndDate']['results'][0]['activity_dates'][2]['iso_date']
    ###end
    return allProjectsData
  end

  def get_country_all_projects_rss(countryCode)
    rssJSON = RestClient.get settings.oipa_api_url + "activities/?format=json&reporting_organisation=GB-GOV-1&hierarchy=1&related_activity_recipient_country=#{countryCode}&ordering=-last_updated_datetime&fields=last_updated_datetime,title,descriptions,iati_identifier&page_size=500"
    rssData = JSON.parse(rssJSON)
    rssResults = rssData['results']
  end
  
  def total_country_budget_location
    firstDayOfFinYear = first_day_of_financial_year(DateTime.now)
    lastDayOfFinYear = last_day_of_financial_year(DateTime.now)
    totalCountryBudgetLocation = RestClient.get settings.oipa_api_url + "activities/aggregations/?reporting_organisation=GB-GOV-1&group_by=recipient_country&aggregations=budget&budget_period_start=#{firstDayOfFinYear}&budget_period_end=#{lastDayOfFinYear}&order_by=-budget&format=json"
    totalCountryBudgetLocation = JSON.parse(totalCountryBudgetLocation)
    totalAmount = 0.0
    totalCountryBudgetLocation['results'].each do |countryBudgets|
      totalAmount = totalAmount + countryBudgets['budget'].to_f
    end
    totalAmount = (format_million_stg totalAmount.to_f).to_s.gsub("&pound;","")
    totalAmount
  end
end