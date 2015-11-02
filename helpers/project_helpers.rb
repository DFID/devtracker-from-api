#require "helpers/codelists"
#require "helpers/lookups"


module ProjectHelpers

    
    include CodeLists

    def dfid_country_map_data
        current_first_day_of_financial_year = first_day_of_financial_year(DateTime.now)
        current_last_day_of_financial_year = last_day_of_financial_year(DateTime.now)
        
        oipaCountryProjectValuesJSON = RestClient.get settings.oipa_api_url + "activities/aggregations?format=json&reporting_organisation=GB-1&budget_period_start=#{settings.current_first_day_of_financial_year}&budget_period_end=#{settings.current_last_day_of_financial_year}&group_by=recipient_country&aggregations=count,budget&order_by=recipient_country"
        projectValues = JSON.parse(oipaCountryProjectValuesJSON)
        projectValues = projectValues['results']
        countriesList = JSON.parse(File.read('data/countries.json'))
        
        # Map the input data structure so that it matches the required input for Tilestream
        projectValuesMapInput = projectValues.map do |elem|
        {
            elem["recipient_country"]["code"] => {
                 "country" => countriesList.find do |source|
                                  source["code"].to_s == elem["recipient_country"]["code"]
                              end["name"],  
                 "id" => elem["recipient_country"]["code"],
                 "projects" => elem["count"],
                 "budget" => elem["budget"],
                 "flag" => '/images/flags/' + elem["recipient_country"]["code"].downcase + '.png'
                }
        }
        end
        # Edit the returned hash object so that the data is in the correct format (e.g. remove enclosing [])
        projectValuesMapInput.to_s.gsub("[", "").gsub("]", "").gsub("=>",":").gsub("}}, {","},")
    end

    def dfid_complete_country_list
        countriesList = JSON.parse(File.read('data/dfidCountries.json')).sort_by{ |k| k["name"]}
        #The API call code was replaced to reduce the page load times
        
#        oipaAllDfidProjectsJSON = RestClient.get settings.oipa_api_url + "activities/aggregations?format=json&reporting_organisation=GB-1&group_by=recipient_country&aggregations=count,budget"
#        allDfidProjects = JSON.parse(oipaAllDfidProjectsJSON)
#        countriesList = JSON.parse(File.read('data/countries.json'))

        # Map the input data structure so that the appropriate country names are used
#        allDfidProjectsMapInput = allDfidProjects.map do |elem|
#        {
#                "code" => elem["recipient_country"]["code"],   
#                "name" => countriesList.find do |source|
#                               source["code"].to_s == elem["recipient_country"]["code"]
#                             end["name"]                                             
#        }
#        end

        # Sort the countries by name
#        allDfidProjectsSorted = allDfidProjectsMapInput.sort_by{ |k| k["name"]}    
    end

    def dfid_regional_projects_data
        
        current_first_day_of_financial_year = first_day_of_financial_year(DateTime.now)
        current_last_day_of_financial_year = last_day_of_financial_year(DateTime.now)    

        # aggregates budgets of the dfid regional projects that are active in the current FY
        oipaAllRegionsJSON = RestClient.get settings.oipa_api_url + "activities/aggregations?format=json&reporting_organisation=GB-1&budget_period_start=#{settings.current_first_day_of_financial_year}&budget_period_end=#{settings.current_last_day_of_financial_year}&group_by=recipient_region&aggregations=count,budget";
        allCurrentRegions = JSON.parse(oipaAllRegionsJSON)
        allCurrentRegions = allCurrentRegions['results']

        # Map the input data structure so that it matches the required input for the Regions map
        allRegionsChartData = allCurrentRegions.map do |elem|
        {
            "region" => elem["recipient_region"]["name"].to_s.gsub(", regional",""),
            "code" => elem["recipient_region"]["code"],
            "budget" => elem["budget"]                           
        }
        end
               
        # Find the total budget for all of the Regions
        totalBudget = Float(allRegionsChartData.map { |s| s["budget"].to_f }.inject(:+))

        # Format the Budget for use on the region chart
        totalBudgetFormatted = (format_million_stg totalBudget.to_f).to_s.gsub("&pound;","")

        # Format the output of the chart data
        allRegionsChartDataFormatted = allRegionsChartData.to_s.gsub("=>",":")

        returnObject = {
            :regionsData => allRegionsChartDataFormatted,            
            :totalBudget => totalBudget,  
            :totalBudgetFormatted => totalBudgetFormatted                              
        }
    end

    def dfid_complete_region_list        
        regionsList = JSON.parse(File.read('data/dfidRegions.json')).sort_by{ |k| k["region"]}    
    end    


    def dfid_global_projects_data
        
        globalProjectsData = JSON.parse(File.read('data/globalProjectsData.json')).sort_by{ |k| k["region"]}

        #Format the output of globalProjectsData
        globalProjectsDataFormatted = globalProjectsData.to_s.gsub("=>",":")

        #Find the total budget for all of the Regions
        totalBudget = Float(globalProjectsData.map { |s| s["budget"].to_f }.inject(:+))

        #Format the Budget for use on the region chart
        totalBudgetFormatted = (format_million_stg totalBudget.to_f).to_s.gsub("&pound;","")

        returnObject = {
            :globalData => globalProjectsDataFormatted,
            :globalDataJSON => globalProjectsData,
            :totalBudget => totalBudget,  
            :totalBudgetFormatted => totalBudgetFormatted                              
         }        

    end

    def h2Activity_title(h2Activities,h2ActivityId)
        if h2Activities.length>0 then
            h2Activity = h2Activities.select {|activity| activity['iati_identifier'] == h2ActivityId}.first
            h2Activity['title']['narratives'][0]['text']
        else
            ""
        end        
    end

    def get_funding_project_Details(projectId)
        fundingProjectDetailsJSON = RestClient.get settings.oipa_api_url + "activities/#{projectId}?format=json" 
        fundingProjectDetails = JSON.parse(fundingProjectDetailsJSON)
        #fundingProject = fundingProjectDetails['results'][0]
    end

    def reporting_organisation(project)
        begin
            organisation = project['reporting_organisations'][0]['narratives'][0]['text']
        rescue
            organisation = project['reporting_organisations'][0]['type']['name']
        end
    end

    def get_implementing_orgs(projectId)
        if is_dfid_project(projectId) then
            implementingOrgsDetailsJSON = RestClient.get settings.oipa_api_url + "activities?format=json&reporting_organisation=GB-1&hierarchy=2&related_activity_id=#{projectId}&fields=participating_organisations"
        else
            implementingOrgsDetailsJSON = RestClient.get settings.oipa_api_url + "activities?format=json&hierarchy=2&id=#{projectId}&fields=participating_organisations"    
        end    
        implementingOrgsDetails = JSON.parse(implementingOrgsDetailsJSON)
        data=implementingOrgsDetails['results']

        implementingOrg = data.collect{ |activity| activity['participating_organisations'][0]}.uniq.compact
        implementingOrg = implementingOrg.select{ |activity| activity['role']['code']=="4"}
    end

    def get_project_sector_graph_data(projectId)
        if is_dfid_project(projectId) then
            projectSectorGraphJSON = RestClient.get settings.oipa_api_url + "activities/aggregations?format=json&reporting_organisation=GB-1&hierarchy=2&related_activity_id=#{projectId}&group_by=sector&aggregations=budget&order_by=-budget&page_count=1000"
        else
            projectSectorGraphJSON = RestClient.get settings.oipa_api_url + "activities/aggregations?format=json&id=#{projectId}&group_by=sector&aggregations=budget&order_by=-budget&page_count=1000"  
        end
        projectSectorGraph = JSON.parse(projectSectorGraphJSON)
        
        c3ReadyStackBarData = Array.new
        
        if projectSectorGraph['count'] > 0
            projectSector= projectSectorGraph['results'] 
            totalBudgets = projectSector.reduce(0) {|memo, t| memo + t['budget'].to_f} 
            #highLevelSectorListData = high_level_sector_list( countrySpecificsectorValuesJSONLink, "all_sectors", "High Level Code (L1)", "High Level Sector Description")
            #sectorWithTopBudgetHash = {}
            c3ReadyStackBarData[0] = ''
            c3ReadyStackBarData[1] = '['
            projectSector.each do |sector|
                sectorGroupPercentage = (100*sector['budget'].to_f/totalBudgets.to_f).round(2)
                c3ReadyStackBarData[0].concat("['"+sector['sector']['name']+"',"+sectorGroupPercentage.to_s+"],")
                #c3ReadyDonutData[0].concat("['"+sectorWithTopBudgetHash.key(tempBudgetValue)+"',"+tempBudgetValue.to_s+"],")
                c3ReadyStackBarData[1].concat("'"+sector['sector']['name']+"',")
            end
            #c3ReadyStackBarData[0].chop
            #c3ReadyStackBarData[1].chop
            c3ReadyStackBarData[1].concat(']')
            return c3ReadyStackBarData
        else
            c3ReadyStackBarData[0] = '["No data available for this view",0]'
            c3ReadyStackBarData[1] = "['No data available for this view']"
            return c3ReadyStackBarData
        end
    end

    def get_project_budget(projectId)
        if is_dfid_project(projectId) then
            projectBudgetJSON = RestClient.get settings.oipa_api_url + "activities/aggregations?format=json&reporting_organisation=GB-1&related_activity_id=#{projectId}&group_by=related_activity&aggregations=expenditure,disbursement,budget"
        else
            projectBudgetJSON = RestClient.get settings.oipa_api_url + "activities/aggregations?format=json&id=#{projectId}&group_by=related_activity&aggregations=expenditure,disbursement,budget"
        end

        projectBudget=JSON.parse(projectBudgetJSON)

        if projectBudget['count'] > 0 then
            projectBudget = projectBudget['results'][0]

            if !projectBudget.key?('disbursement') && !projectBudget.key?('expenditure') then
                spendBudget = 0
            elsif !projectBudget.key?('disbursement') then
                spendBudget = projectBudget['expenditure']
            elsif !projectBudget.key?('expenditure') then
                spendBudget = projectBudget['disbursement']    
            else
                spendBudget = projectBudget['expenditure'] + projectBudget['disbursement']
            end

            if !projectBudget.key?('budget') then
                actualBudget=0
            else
                actualBudget = projectBudget['budget']
            end    
        else
            spendBudget = 0
            actualBudget = 0
        end

        returnObject = {
            :spendBudget => spendBudget,
            :actualBudget => actualBudget
          }        
    end
    

    #def transaction_description(transaction, transactionType)
    #    if(transactionType == "C")
    #        transaction['title'] || ""
    #    elsif(transactionType == "IF")
    #        transaction_title(transactionType)
    #    else
    #        transaction['description']
    #    end
    #end

    def get_sum_transaction(transactionType)
        summedBudgets = transactionType.reduce(0) {|memo, t| memo + t['value'].to_f}
    end

    def get_sum_budget(projectBudgets)
        if !projectBudgets.nil? && projectBudgets.length > 0 then
            summedBudgets = projectBudgets.reduce(0) {|memo, t| memo + t[1].to_f}
        else
            summedBudgets = 0
        end    
    end

    def is_dfid_project(projectCode)   
        projectCode[0, 5] == "GB-1-"
    end

    def first_day_of_financial_year(date_value)
        if date_value.month > 3 then
            Date.new(date_value.year, 4, 1)
        else
            Date.new(date_value.year - 1, 4, 1)
        end
    end

    def last_day_of_financial_year(date_value)
        if date_value.month > 3 then
            Date.new(date_value.year + 1, 3, 31)
        else
            Date.new(date_value.year, 3, 31)
        end
    end

    def choose_better_date(actual, planned)
        # determines project actual start/end date - use actual date, planned date as a fallback
        unless actual.nil? || actual == ''
            actual = Time.parse(actual)
            return (Time.at(actual).to_f * 1000.0).to_i
        end

        unless planned.nil? || planned == ''
            planned = Time.parse(planned)
            return (Time.at(planned).to_f * 1000.0).to_i
        end

        return 0
    end

    def choose_better_date_label(actual, planned)
        # determines project actual start/end date - use actual date, planned date as a fallback
        unless actual.nil? || actual == ''
            return "Actual"
        end

        unless planned.nil? || planned == ''
            return "Planned"
        end

        return ""
    end

    
    def coerce_budget_vs_spend_items(cursor, type) 
        cursor.to_a.group_by { |b| 
            # we want to group them by the first day of 
            # the financial year. This allows for calculations
            date = if b['date'].kind_of?(String) then
              Date.parse(b['date'])
            else
              b['date'].to_date
            end
            first_day_of_financial_year(date)
        }.map { |fy, bs| 
            # then we sum up all the values for that financial year
            {
                'type'  => type,
                "fy"    => fy,
                "value" => bs.inject(0) { |v, b| v + b['value'] },
            }
        }
    end

    #End TODO

    

end

#helpers ProjectHelpers
