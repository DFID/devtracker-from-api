module CountryHelpers

  def country_project_budgets(yearWiseBudgets)
    projectBudgets = []
    
    yearWiseBudgets.each do |y|
      if y["quarter"]==1
          p=[y["quarter"],y["budget"],y["year"],y["year"]-1]
      else
          p=[y["quarter"],y["budget"],y["year"],y["year"]]
      end
      
      projectBudgets << p        
    end
     
     finYearWiseBudgets = projectBudgets.group_by{|b| b[3]}.map{|year, budgets|
        summedBudgets = budgets.reduce(0) {|memo, budget| memo + budget[1]}
        [year, summedBudgets]
        }.sort   

    # determine what range to show
      #current_financial_year = first_day_of_financial_year(DateTime.now)
      currentFinancialYear = financial_year

    # if range is 6 or less just show it
      range = if finYearWiseBudgets.size < 7 then
               finYearWiseBudgets
              # if the last item in the list is less than or equal to 
              # the current financial year get the last 6
              elsif finYearWiseBudgets.last.first <= currentFinancialYear
                finYearWiseBudgets.last(6)
              # other wise show current FY - 3 years and cuurent FY + 3 years
              else
                index_of_now = finYearWiseBudgets.index { |i| i[0] == currentFinancialYear }

                if index_of_now.nil? then
                  finYearWiseBudgets.last(6)
                else
                  finYearWiseBudgets[[index_of_now-3,0].max..index_of_now+2]
                end
              end

              # finally convert the range into a label format
              range.each { |item| 
                item[0] = financial_year_formatter(item[0]) 
              }

  end

  def financial_year_formatter(y)

    #date = if(d.kind_of?(String)) then
      #Date.parse d
    #else
      #d
    #end

    #if date.month < 4
      #{}"FY#{(date.year-1).to_s[2..3]}/#{date.year.to_s[2..3]}"
    #else
      "FY#{y.to_s[2..3]}/#{(y+1).to_s[2..3]}"
    #end
  end

  def financial_year 
    now = Time.new
    if(now.month < 4)
      now.year-1
    else
      now.year
    end
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

  def get_country_sector_graph_data(countrySpecificsectorValuesJSONLink)
    budgetPercentageArray = Array.new
    highLevelSectorListData = high_level_sector_list( countrySpecificsectorValuesJSONLink, "all_sectors", "High Level Code (L1)", "High Level Sector Description")
    sectorWithTopBudgetHash = {}
    highLevelSectorListData[:sectorsData].each do |sector|
      sectorGroupPercentage = (100*sector[:budget].to_f/highLevelSectorListData[:totalBudget].to_f).round(2)
      sectorWithTopBudgetHash[sector[:name]] = sectorGroupPercentage
      budgetPercentageArray.push(sectorGroupPercentage)
    end
    budgetPercentageArray.sort!
    #Fixing the donut data here
    topFiveTracker = 0
    c3ReadyDonutData = ''
    otherBudgetPercentage = 0.0
    while !budgetPercentageArray.empty?
      if(topFiveTracker < 5)
          topFiveTracker = topFiveTracker + 1
          tempBudgetValue = budgetPercentageArray.pop
          c3ReadyDonutData.concat("['"+sectorWithTopBudgetHash.key(tempBudgetValue)+"',"+tempBudgetValue.to_s+"],")
      else
          otherBudgetPercentage = otherBudgetPercentage + budgetPercentageArray.pop
      end
    end
    c3ReadyDonutData.concat("['Other',"+ otherBudgetPercentage.to_s+"]")
    return c3ReadyDonutData
  end
end