#require "helpers/codelists"
#require "helpers/lookups"

module ProjectHelpers

    
    include CodeLists

    def dfid_total_projects_budget(projectType)
        # aggregates a total budget of all the dfid projects for a given type (global, coutry, regional)
        (dfid_projects_budget(projectType).first || { 'total' => 0 })['total']
    end

    def dfid_projects_budget(projectType)
        @cms_db['projects'].aggregate([{
            "$group" => {
                "_id"   => "$projectType",
                "total" => {
                    "$sum" => "$currentFYBudget"
                }
            } }, {
                "$match" => {
                    "_id" => projectType
                }
            }]
        )
    end

    def is_dfid_project(projectCode)   
        projectCode[0, 4] == "GB-1"
    end

    def dfid_region_projects_budget(regionCode)
        # aggregates a total budget of all the regional projects for the given region code
        result = @cms_db['projects'].aggregate([{
            "$match" => {
                "projectType" => "regional",
                "recipient" => regionCode
                }
            }, {
                "$group" => {
                    "_id" => "$recipient",
                    "total" => {
                        "$sum" => "$currentFYBudget"
                    }
                }
            }]
        )
        (result.first || { 'total' => 0 })['total']
    end

    def dfid_country_map_data
        current_first_day_of_financial_year = first_day_of_financial_year(DateTime.now)
        current_last_day_of_financial_year = last_day_of_financial_year(DateTime.now)
        
        oipaCountryProjectValuesJSON = RestClient.get settings.oipa_api_url + "activities/aggregations?format=json&reporting_organisation=GB-1&budget_period_start=#{settings.current_first_day_of_financial_year}&budget_period_end=#{settings.current_last_day_of_financial_year}&group_by=recipient_country&aggregations=count,budget&order_by=recipient_country"
        projectValues = JSON.parse(oipaCountryProjectValuesJSON)
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
        
        oipaAllDfidProjectsJSON = RestClient.get settings.oipa_api_url + "activities/aggregations?format=json&reporting_organisation=GB-1&group_by=recipient_country&aggregations=count,budget"
        allDfidProjects = JSON.parse(oipaAllDfidProjectsJSON)
        countriesList = JSON.parse(File.read('data/countries.json'))

        # Map the input data structure so that the appropriate country names are used
        allDfidProjectsMapInput = allDfidProjects.map do |elem|
        {
                "code" => elem["recipient_country"]["code"],   
                "name" => countriesList.find do |source|
                               source["code"].to_s == elem["recipient_country"]["code"]
                             end["name"]                                             
        }
        end

        # Sort the countries by name
        allDfidProjectsSorted = allDfidProjectsMapInput.sort_by{ |k| k["name"]}
    end

    def dfid_regional_projects_data
        
        current_first_day_of_financial_year = first_day_of_financial_year(DateTime.now)
        current_last_day_of_financial_year = last_day_of_financial_year(DateTime.now)    

        # aggregates budgets of the dfid regional projects grouping them by regions
        oipaAllRegionsJSON = RestClient.get settings.oipa_api_url + "activities/aggregations?format=json&reporting_organisation=GB-1&budget_period_start=#{settings.current_first_day_of_financial_year}&budget_period_end=#{settings.current_last_day_of_financial_year}&group_by=recipient_region&aggregations=count,budget";
        allRegions = JSON.parse(oipaAllRegionsJSON)

        # Map the input data structure so that it matches the required input for the Regions map
        allRegionsChartData = allRegions.map do |elem|
        {
            "region" => elem["recipient_region"]["name"].to_s.gsub(", regional",""),
            "code" => elem["recipient_region"]["code"],
            "budget" => elem["budget"]                           
        }
        end
               
        #Find the total budget for all of the Regions
        totalBudget = Float(allRegionsChartData.map { |s| s["budget"].to_f }.inject(:+))

        #Format the Budget for use on the region chart
        totalBudgetFormatted = (format_million_stg totalBudget.to_f).to_s.gsub("&pound;","")

        #Format the output of the chart data
        allRegionsChartDataFormatted = allRegionsChartData.to_s.gsub("=>",":")

        returnObject = {
            :regionsData => allRegionsChartDataFormatted,
            :totalBudget => totalBudget,  
            :totalBudgetFormatted => totalBudgetFormatted                              
         }
    end

    def dfid_global_projects_data
        current_first_day_of_financial_year = first_day_of_financial_year(DateTime.now)
        current_last_day_of_financial_year = last_day_of_financial_year(DateTime.now)    

        # aggregates budgets of the dfid regional projects grouping them by regions
        oipaGlobalProjectsJSON = RestClient.get settings.oipa_api_url + "activities/aggregations?format=json&reporting_organisation=GB-1&group_by=reporting_organisation&aggregations=count,budget&order_by=-budget&budget_period_start=2015-04-01&budget_period_end=2016-03-31&xml_source_ref=dfid-ns1,dfid-ns2,zz";
        allGlobalProjects = JSON.parse(oipaGlobalProjectsJSON)

        # Map the input data structure so that it matches the required input for the Regions map
        globalProjectsChartData = allGlobalProjects.map do |elem|
        {
            "budget" => elem["budget"]                           
        }
        end
               
        #Find the total budget for all of the Regions
        totalBudget = Float(globalProjectsChartData.map { |s| s["budget"].to_f }.inject(:+))

        #Format the Budget for use on the region chart
        totalBudgetFormatted = (format_million_stg totalBudget.to_f).to_s.gsub("&pound;","")

        #Format the output of the chart data
   #     allRegionsChartDataFormatted = allRegionsChartData.to_s.gsub("=>",":")

        returnObject = {
    #        :regionsData => allRegionsChartDataFormatted,
            :totalBudget => totalBudget,  
            :totalBudgetFormatted => totalBudgetFormatted                              
         }        
    end



    def dfid_global_projects
        @@global_recipients.map { |code, name|
            {
                :code   => code,
                :region => name,
                :budget => (@cms_db['projects'].aggregate([{
                    "$match" => {
                        'projectType' => 'global',
                        'recipient'   => code
                    },
                }, {
                    "$group" => {
                        "_id" => nil,
                        "total" => { "$sum" => "$currentFYBudget" }
                    }
                }]).first || {"total" => 0})["total"]
            }
        }
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

    def project_budgets(projectId)
        project_budgets = @cms_db['project-budgets'].find({
              'id' => projectId
            }).to_a
        graph = []
        graph + project_budgets.inject({}) { |results, budget| 
          fy = financial_year_formatter budget['date']
          results[fy] = (results[fy] || 0) + budget['value']
          results
        }.map { |fy, budget| [fy, budget] }.inject({}) { |graph, group|
          graph[group.first] = (graph[group.first] || 0) + group.last
          graph
        }.map { |fy, budget| [fy, budget] }.sort
    end

    def project_budget_per_fy(projectId)
        # # project all budgets into a suitable format
        # budgets = coerce_budget_vs_spend_items(
        #     @cms_db['project-budgets'].find(
        #         { "id" => projectId }, :sort => ['date', Mongo::DESCENDING]
        #     ), "budget"
        # )

        # # project all spends into a suitable format
        # spends = coerce_budget_vs_spend_items(
        #     @cms_db['transactions'].find({
        #         "project" => projectId,
        #         'type'    => {
        #             '$in' => ['D', 'E']
        #         }
        #     }), "spend"
        # )

        # # merge the series and sort by financial year
        # series = (spends + budgets).group_by { |item|
        #     item['fy']
        # }.map { |fy, items|
        #     # So we coerce this into a partially projected list of pairs
        #     [
        #         fy,
        #         (items.find { |b| b['type'] == 'budget' } || {'value' => 0})['value'],
        #         (items.find { |b| b['type'] == 'spend' } || {'value' => 0})['value']
        #     ]
        # }.sort_by { |item| item.first }

        # # determine what range to show
        # current_financial_year = first_day_of_financial_year(DateTime.now)

        # # if range is 6 or less just show it
        # range = if series.size < 7 then
        #   series
        # # if the last item in the list is less than or equal to 
        # # the current financial year get the last 6
        # elsif series.last.first <= current_financial_year
        #   series.last(6)
        # # other wise show current FY - 3 years and cuurent FY + 3 years
        # else
        #   index_of_now = series.index { |i| i[0] == current_financial_year }

        #   if index_of_now.nil? then
        #     series.last(6)
        #   else
        #     series[[index_of_now-3,0].max..index_of_now+2]
        #   end
        # end

        # # finally convert the range into a label format
        # range.each { |item| 
        #   item[0] = financial_year_formatter(item[0]) 
        # }

        # range
    end

    def total_project_budget(projectId)
        # aggregates and sums the budgets for a given project
        result = @cms_db['project-budgets'].aggregate([{
                "$match" => {
                    "id" => projectId
                }
            }, {
                "$group" => { 
                    "_id" => nil,
                    "total" => {
                        "$sum" => "$value"
                    }
                }
            }]
        )

        if result.size > 0 then
            result.first['total']
        else 
            0
        end


    end

    def project_sector_groups(projectId)        
        sectorGroups = @cms_db['project-sector-budgets'].find({
            "projectIatiId" => projectId
        }).map { |s| {
            "name"   => s['sectorName'] || sector(s['sectorCode']),
            "code"   => s['sectorCode'],
            "budget" => s['sectorBudget']
        }}
        if sectorGroups.any? then
            sectorGroups = sectorGroups.group_by { |s| 
                s['code'] }.map do |code, sectors| { 
                "code" => code, "name" => sectors[0]["name"], "budget" => sectors.map { |sec| sec["budget"] }.inject(:+)
            } end.sort_by{ |sg| -sg["budget"]}
            sectorsTotalBudget = Float(sectorGroups.map {|s| s["budget"]}.inject(:+))

            sectorGroups.map { |sg| {
                :sector => sg['name'],
                :budget => sg['budget'] / sectorsTotalBudget * 100.0,
                :formatted => format_percentage(sg['budget'] / sectorsTotalBudget * 100)
            }}
        else
            return sectorGroups
        end
    end

    def transaction_description(transaction, transactionType)
        if(transactionType == "C")
            transaction['title'] || ""
        elsif(transactionType == "IF")
            transaction_title(transactionType)
        else
            transaction['description']
        end
    end

    def associated_country(projectCode)
        country = @cms_db['countries'].find_one({'code' => projectCode}) || {"name" => ""} 
        country['name']
    end

    def project_documents(projectCode)
        @cms_db['documents'].find({ 'project' => projectCode}).count
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

    #New Function for API Based Devtracker
    def h2Activity_title(h2Activities,h2ActivityId)
        if h2Activities.length>0 then
            h2Activity = h2Activities.select {|activity| activity['id'] == h2ActivityId}.first
            h2Activity['title']['narratives'][0]['text']
        else
            ""
        end        
    end

    def sum_transaction_value(transactionType)
        summedBudgets = transactionType.reduce(0) {|memo, t| memo + t['value'].to_f}
        
        #total_transaction_value['summedBudgets']
    end

    def sum_budget_value(projectBudgets)
        if !projectBudgets.nil? && projectBudgets.length > 0 then
            summedBudgets = projectBudgets.reduce(0) {|memo, t| memo + t[1].to_f}
        else
            summedBudgets =0
        end    
    end

end

helpers ProjectHelpers
