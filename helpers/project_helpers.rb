#require "helpers/codelists"
#require "helpers/lookups"


module ProjectHelpers

    
    include CodeLists
    include CommonHelpers

    def get_h1_project_details(projectId)
        oipa = RestClient.get settings.oipa_api_url + "activities/#{projectId}/?format=json"
        project = JSON.parse(oipa)
        project['document_links'] = get_h1_project_document_details(projectId,project)
        project
    end

    def get_h1_project_document_details(projectId,projectJson)
        project_documents = projectJson['document_links']
        static_projects = JSON.parse(File.read('data/document_exclusion_list.json'))
        static_projects = static_projects.select{ |p| p['project'] == projectId }
        puts static_projects
        if static_projects.length > 0
            project_documents.delete_if do |pd|
                flag = 0
                static_projects.each do |sp|
                    if (pd['url'].include? sp['qid'].to_s)
                        flag = 1
                        break
                    end
                end
                if flag == 1
                    true
                else
                    false
                end
            end
        end
        project_documents
    end

    def get_h2_project_details(projectId)
        oipa = RestClient.get settings.oipa_api_url + "activities/?format=json&related_activity_id=#{projectId}&page_size=50&fields=iati_identifier,title"
        project = JSON.parse(oipa)
        project = project['results']
    end

    def get_funding_project_count(projectId)
        oipa = RestClient.get settings.oipa_api_url + "activities/#{projectId}/transactions/?format=json&transaction_type=1&fields=url"
        project = JSON.parse(oipa)
        project = project['count']
    end

    def get_funded_project_count(projectId)
        oipa = RestClient.get settings.oipa_api_url + "activities/?format=json&transaction_provider_activity=#{projectId}&fields=url"
        project = JSON.parse(oipa)
        project = project['count']
    end

    def get_funding_project_details(projectId)
        fundingProjectsAPI = RestClient.get settings.oipa_api_url + "activities/#{projectId}/transactions/?format=json&transaction_type=1&page_size=1000" 
        fundingProjectsData = JSON.parse(fundingProjectsAPI)
    end

    def get_funded_project_details(projectId)
        fundedProjectsAPI = RestClient.get settings.oipa_api_url + "activities/?format=json&transaction_provider_activity=#{projectId}&page_size=1000&fields=id,title,descriptions,reporting_organisations,activity_plus_child_aggregation,default_currency,aggregations&ordering=title"
        fundedProjectsData = JSON.parse(fundedProjectsAPI)
    end

    def get_transaction_details(projectId)
        if is_dfid_project(projectId) then
            oipaTransactionsJSON = RestClient.get settings.oipa_api_url + "transactions/?format=json&activity_related_activity_id=#{projectId}&page_size=400&fields=aggregations,activity,description,provider_organisation,provider_activity,receiver_organisation,transaction_date,transaction_type,value,currency"
        else
            oipaTransactionsJSON = RestClient.get settings.oipa_api_url + "transactions/?format=json&activity=#{projectId}&page_size=400&fields=aggregations,activity,description,provider_organisation,receiver_organisation,transaction_date,transaction_type,value,currency"
        end

        transactionsJSON = JSON.parse(oipaTransactionsJSON)
        transactions = transactionsJSON['results'].select {|transaction| !transaction['transaction_type'].nil? }
    end

    def get_project_yearwise_budget(projectId)
        
        if is_dfid_project(projectId) then
            oipaYearWiseBudgets=RestClient.get settings.oipa_api_url + "activities/aggregations/?format=json&reporting_organisation=GB-GOV-1&group_by=budget_per_quarter&aggregations=budget&related_activity_id=#{projectId}&order_by=year,quarter"
        else
            oipaYearWiseBudgets=RestClient.get settings.oipa_api_url + "activities/aggregations/?format=json&group_by=budget_per_quarter&aggregations=budget&id=#{projectId}&order_by=year,quarter"
        end

        yearWiseBudgets=JSON.parse(oipaYearWiseBudgets)
        projectBudgets=financial_year_wise_budgets(yearWiseBudgets['results'].select {|project| !project['budget'].nil? },"P")
    end

    def dfid_complete_country_list
        countriesList = JSON.parse(File.read('data/dfidCountries.json')).sort_by{ |k| k["name"]}
    end

    def dfid_country_map_data
        current_first_day_of_financial_year = first_day_of_financial_year(DateTime.now)
        current_last_day_of_financial_year = last_day_of_financial_year(DateTime.now)
        #OIPA V2.2
        #oipaCountryProjectBudgetValuesJSON = RestClient.get settings.oipa_api_url + "activities/aggregations/?format=json&reporting_organisation=GB-GOV-1&budget_period_start=#{current_first_day_of_financial_year}&budget_period_end=#{current_last_day_of_financial_year}&group_by=recipient_country&aggregations=count,budget&order_by=recipient_country"
        #OIPA V3.1
        oipaCountryProjectBudgetValuesJSON = RestClient.get settings.oipa_api_url + "budgets/aggregations/?format=json&reporting_organisation=GB-GOV-1&budget_period_start=#{current_first_day_of_financial_year}&budget_period_end=#{current_last_day_of_financial_year}&group_by=recipient_country&aggregations=count,value&order_by=recipient_country"
        projectBudgetValues = JSON.parse(oipaCountryProjectBudgetValuesJSON)
        projectBudgetValues = projectBudgetValues['results']
        oipaCountryProjectCountJSON = RestClient.get settings.oipa_api_url + "activities/aggregations/?format=json&hierarchy=1&reporting_organisation=GB-GOV-1&group_by=recipient_country&aggregations=count&reporting_organisation=GB-GOV-1&activity_status=2"
        projectValues = JSON.parse(oipaCountryProjectCountJSON)
        projectCountValues = projectValues['results']
        countriesList = JSON.parse(File.read('data/countries.json'))
        
        projectDataHash = {}
        projectCountValues.each do |project|
            tempBudget = projectBudgetValues.find do |projectBudget|
                projectBudget["recipient_country"]["code"].to_s == project["recipient_country"]["code"]
            end
            tempCountry = countriesList.find do |source|
                source["code"].to_s == project["recipient_country"]["code"]
            end
            projectDataHash[project["recipient_country"]["code"]] = {}
            projectDataHash[project["recipient_country"]["code"]]["country"] = tempCountry["name"]
            projectDataHash[project["recipient_country"]["code"]]["id"] = project["recipient_country"]["code"]
            projectDataHash[project["recipient_country"]["code"]]["projects"] = project["count"]
            #OIPA V2.2
            #projectDataHash[project["recipient_country"]["code"]]["budget"] = tempBudget.nil? ? 0 : tempBudget["budget"]
            #OIPA V3.1
            projectDataHash[project["recipient_country"]["code"]]["budget"] = tempBudget.nil? ? 0 : tempBudget["value"]
            projectDataHash[project["recipient_country"]["code"]]["flag"] = '/images/flags/' + project["recipient_country"]["code"].downcase + '.png'
            puts project["recipient_country"]["name"]
        end

        # Map the input data structure so that it matches the required input for Tilestream

        # projectValuesMapInput = projectBudgetValues.map do |elem|
        # {
        #     elem["recipient_country"]["code"] => {
        #          "country" => countriesList.find do |source|
        #                           source["code"].to_s == elem["recipient_country"]["code"]
        #                       end["name"],  
        #          "id" => elem["recipient_country"]["code"],
        #          "projects" => projectCountValues.find do |project|
        #                            project["recipient_country"]["code"].to_s == elem["recipient_country"]["code"]
        #                        end["count"],
        #           "budget" => elem["budget"],
        #          "flag" => '/images/flags/' + elem["recipient_country"]["code"].downcase + '.png'
        #         }
        # }
        # end
        # Edit the returned hash object so that the data is in the correct format (e.g. remove enclosing [])
        #puts projectValuesMapInput
        #projectValuesMapInput.to_s.gsub("[", "").gsub("]", "").gsub("=>",":").gsub("}}, {","},")
        projectDataHash.to_s.gsub("[", "").gsub("]", "").gsub("=>",":").gsub("}}, {","},")
    end

    

    def get_h2Activity_title(h2Activities,h2ActivityId)
        if h2Activities.length>0 then
            h2Activity = h2Activities.select {|activity| activity['iati_identifier'] == h2ActivityId}.first
            h2Activity.blank? ? ('') : (h2Activity['title']['narratives'][0]['text'])
        else
            ""
        end        
    end

    def get_funding_project(projectId)
        fundingProjectDetailsJSON = RestClient.get settings.oipa_api_url + "activities/#{projectId}/?format=json" 
        fundingProjectDetails = JSON.parse(fundingProjectDetailsJSON)
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
            implementingOrgsDetailsJSON = RestClient.get settings.oipa_api_url + "activities/?format=json&reporting_organisation=GB-GOV-1&hierarchy=2&related_activity_id=#{projectId}&fields=participating_organisations"
        else
            implementingOrgsDetailsJSON = RestClient.get settings.oipa_api_url + "activities/?format=json&hierarchy=1&id=#{projectId}&fields=participating_organisations"    
        end    
        implementingOrgsDetails = JSON.parse(implementingOrgsDetailsJSON)
        implementingOrg=implementingOrgsDetails['results']

        #implementingOrg = data.collect{ |activity| activity['participating_organisations'][2]}.uniq.compact
        #implementingOrg = implementingOrg.select{ |activity| activity['role']['code']=="4"}

        implementingOrgsList = []
        implementingOrg.each do |impOrg|
            impOrg["participating_organisations"].select{|imp| imp["role"]["code"]=="4" }.each do |i|
                if i["narratives"].length > 0 then 
                    implementingOrgsList << i["narratives"][0]["text"]
                end        
            end
        end
        implementingOrgsList = implementingOrgsList.uniq.sort
    end

    def get_project_sector_graph_data(projectId)
        if is_dfid_project(projectId) then
            projectSectorGraphJSON = RestClient.get settings.oipa_api_url + "budgets/aggregations/?format=json&reporting_organisation=GB-GOV-1&hierarchy=2&related_activity_id=#{projectId}&group_by=sector&aggregations=value&order_by=-value&page_count=1000"
        else
            projectSectorGraphJSON = RestClient.get settings.oipa_api_url + "budgets/aggregations/?format=json&id=#{projectId}&group_by=sector&aggregations=value&order_by=-value&page_count=1000"
        end
        projectSectorGraph = JSON.parse(projectSectorGraphJSON)
        
        c3ReadyStackBarData = Array.new
        
        if projectSectorGraph['count'] > 0
            projectSector= projectSectorGraph['results'] 
            totalBudgets = projectSector.reduce(0) {|memo, t| memo + t['budget'].to_f} 
            c3ReadyStackBarData[0] = ''
            c3ReadyStackBarData[1] = '['
            projectSector.each do |sector|
                sectorGroupPercentage = (100*sector['budget'].to_f/totalBudgets.to_f).round(2)
                c3ReadyStackBarData[0].concat('["'+sector['sector']['name']+'",'+sectorGroupPercentage.to_s+"],")
                c3ReadyStackBarData[1].concat('"'+sector['sector']['name']+'",')
            end
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
            projectBudgetJSON = RestClient.get settings.oipa_api_url + "activities/aggregations/?format=json&reporting_organisation=GB-GOV-1&related_activity_id=#{projectId}&group_by=related_activity&aggregations=expenditure,disbursement,budget"
        else
            projectBudgetJSON = RestClient.get settings.oipa_api_url + "activities/aggregations/?format=json&id=#{projectId}&group_by=related_activity&aggregations=expenditure,disbursement,budget"
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

    def project_budget_per_fy(projectId)

        begin #to mask errors in the return of the aggregation for some partner projects.
            if is_dfid_project(projectId) then
                actualBudgetJSON = RestClient.get settings.oipa_api_url + "activities/aggregations/?format=json&reporting_organisation=GB-GOV-1&related_activity_id=#{projectId}&group_by=budget_per_quarter&aggregations=budget"
                disbursementJSON = RestClient.get settings.oipa_api_url + "activities/aggregations/?format=json&reporting_organisation=GB-GOV-1&related_activity_id=#{projectId}&group_by=transactions_per_quarter&aggregations=disbursement"
                expenditureJSON = RestClient.get settings.oipa_api_url + "activities/aggregations/?format=json&reporting_organisation=GB-GOV-1&related_activity_id=#{projectId}&group_by=transactions_per_quarter&aggregations=expenditure"
            else
                actualBudgetJSON = RestClient.get settings.oipa_api_url + "activities/aggregations/?format=json&id=#{projectId}&group_by=budget_per_quarter&aggregations=budget"
                disbursementJSON = RestClient.get settings.oipa_api_url + "activities/aggregations/?format=json&id=#{projectId}&group_by=transactions_per_quarter&aggregations=disbursement"
                expenditureJSON = RestClient.get settings.oipa_api_url + "activities/aggregations/?format=json&id=#{projectId}&group_by=transactions_per_quarter&aggregations=expenditure"
            end

            actualBudget = JSON.parse(actualBudgetJSON)
            actualBudget = actualBudget['results'].select {|project| !project['budget'].nil? }
            disbursement = JSON.parse(disbursementJSON)    
            disbursement = disbursement['results'].select {|project| !project['disbursement'].nil? }
            expenditure = JSON.parse(expenditureJSON)    
            expenditure = expenditure['results'].select {|project| !project['expenditure'].nil? }

            actualBudgetPerFy = get_actual_budget_per_fy(actualBudget)
            disbursementPerFy = get_spend_budget_per_fy(disbursement,"disbursement")
            expenditurePerFy = get_spend_budget_per_fy(expenditure,"expenditure")

            spendBudgetPerFy = (disbursementPerFy + expenditurePerFy).group_by { |item|
                item['fy']
            }.map { |fy, bs|
                {
                    "fy"    => fy,
                    "type"  => "spend",
                    "value" => bs.inject(0) { |v, item| v + item["value"] },
                }   
            }

            # merge the series and sort by financial year
            series = (spendBudgetPerFy + actualBudgetPerFy).group_by { |item|
                item['fy']
            }.map { |fy, items|
                # So we coerce this into a partially projected list of pairs
                [
                    fy,
                    (items.find { |b| b['type'] == 'budget' } || {'value' => 0})['value'],
                    (items.find { |b| b['type'] == 'spend' } || {'value' => 0})['value']
                ]
            }.sort_by { |item| item.first }

            currentFinancialYear = financial_year

            range = if series.size < 7 then
                        series
                    # if the last item in the list is less than or equal to 
                    # the current financial year get the last 6
                    elsif series.last.first <= currentFinancialYear
                        series.last(6)
                    # other wise show current FY - 3 years and cuurent FY + 3 years
                    else
                        index_of_now = series.index { |i| i[0] == currentFinancialYear }

                        if index_of_now.nil? then
                            series.last(6)
                        else
                            series[[index_of_now-3,0].max..index_of_now+2]
                        end
                    end

            tempFYear = ""
            tempBudgetAmount = ""
            tempSpendAmount = ""
            returnGraphData = []
            # finally convert the range into a label format
            range.each { |item| 
              #item[0] = financial_year_formatter(item[0])
              tempFYear  = tempFYear + "'" + financial_year_formatter(item[0]) + "'" + ","
              tempBudgetAmount = tempBudgetAmount + "'" + item[1].to_s + "'" + ","
              tempSpendAmount = tempSpendAmount + "'" + item[2].to_s + "'" + ","
            }
            returnGraphData[0] = tempFYear
            returnGraphData[1] = tempBudgetAmount
            returnGraphData[2] = tempSpendAmount

            return returnGraphData  

        rescue
            #returns empty. Need to test for nil.
        end      
        #return series    
    end

    
    def get_sum_transaction(transactionType)
        summedBudgets = transactionType.reduce(0) {|memo, t| memo + t['value'].to_f}
    end

    def get_sum_budget(projectBudgets)
        if !projectBudgets.nil? && projectBudgets.length > 0 then
            summedBudgets = projectBudgets.reduce(0) {|memo, t| memo + t['value'].to_f}
        else
            summedBudgets = 0
        end    
    end

    def is_dfid_project(projectCode)   
        projectCode[0, 5] == "GB-1-" || projectCode[0, 9] == "GB-GOV-1-"
    end

    def is_valid_project(projectCode)
        if projectCode.length > 4 && projectCode[0, 2] == "GB" then
            return true
        else
            return false
        end        
    end

    def choose_better_currency(dis_curr,exp_curr,default_curr)

        if dis_curr.nil? && exp_curr.nil? then
            return default_curr
        elsif dis_curr.nil? then
            return exp_curr
        else
            return dis_curr
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
