#require "helpers/codelists"
#require "helpers/lookups"


module ProjectHelpers

    
    include CodeLists
    include CommonHelpers

    def check_if_project_exists(projectId)
        begin
            #oipa = RestClient.get  api_simple_log(settings.oipa_api_url + "activities/#{projectId}/?format=json&fields=recipient_country")
            oipa = RestClient.get  api_simple_log(settings.oipa_api_url_solr + 'activity?q=iati_identifier:'+projectId+'&fl=*')
            response = Oj.load(oipa)
            if response['response']['docs'][0].has_key?('recipient_country_code')
                tempData = response['response']['docs'][0]['recipient_country_code'].select{|a| a.to_s == 'UA'}.length()
                if(tempData != 0)
                    halt 404, "Activity not found"
                end
            end   
        rescue => e
            halt 404, "Activity not found"
        end
        return true
    end

    def get_h1_project_details(projectId)
        #oipa = RestClient.get  api_simple_log(settings.oipa_api_url + "activities/#{projectId}/?format=json&fields=all")
        oipa = RestClient.get  api_simple_log(settings.oipa_api_url_solr + 'activity?q=iati_identifier:'+projectId+'&fl=*')
        project = JSON.parse(oipa)
        #project['document_links'] = get_h1_project_document_details(projectId,project)
        project = project['response']['docs'][0]
        project['local_document_links'] = get_document_links_local(projectId)
        #puts 'project details grabbed.'
        project
    end
    
    def get_funded_by_organisations(project)
        #if(is_dfid_project(project['id']))
            if(is_hmg_project(project['response']['']['reporting_org_ref']))
                fundingOrgs = {}
                fundingOrgs['orgList'] = project['participating_org'].select{|org| org['role']['code'] == '1'}
                if(fundingOrgs['orgList'].length > 0)
                    checkIfFundingOrgMatchesWithReportingOrg = fundingOrgs['orgList'].select{|org| org['ref'] == project['reporting_org']['ref']}
                    if(checkIfFundingOrgMatchesWithReportingOrg.length == 1 && fundingOrgs['orgList'].length == 1)
                        fundingOrgs['fundingType'] = 'Do nothing'
                    elsif (checkIfFundingOrgMatchesWithReportingOrg.length == 0 && fundingOrgs['orgList'].length > 0)
                        fundingOrgs['fundingType'] = 'Funded by'
                    else
                        fundingOrgs['fundingType'] = 'Part funded by'
                    end
                end
                fundingOrgs
            else
                nil
            end
        #else
        #    nil
        #end
    end

    def get_participating_organisations(project)
        if(is_hmg_project(project['reporting_org_ref']))
            participatingOrgs = {}
            participatingOrgs['Funding'] = []
            participatingOrgs['Accountable'] = []
            participatingOrgs['Extending'] = []
            participatingOrgs['Implementing'] = []
            if project.has_key?('participating_org_narrative')
                project['participating_org_narrative'].each_with_index do |val, i|
                    if project['participating_org_role'][i].to_i == 1
                        participatingOrgs['Funding'].push(val)
                    elsif project['participating_org_role'][i].to_i == 2
                        participatingOrgs['Accountable'].push(val)
                    elsif project['participating_org_role'][i].to_i == 3
                        participatingOrgs['Extending'].push(val)
                    elsif project['participating_org_role'][i].to_i == 4
                        participatingOrgs['Implementing'].push(val)
                    end
                end
            end
            # participatingOrgs['Funding'] = project['participating_org'].select{|org| org['role']['code'].to_i == '1'}
            # participatingOrgs['Accountable'] = project['participating_org'].select{|org| org['role']['code'].to_i == '2'}
            # participatingOrgs['Extending'] = project['participating_org'].select{|org| org['role']['code'].to_i == '3'}
            # participatingOrgs['Implementing'] = project['participating_org'].select{|org| org['role']['code'].to_i == '4'}
            participatingOrgs
        else
            nil
        end
    end

    def get_document_links_local(projectId)
        local_documents = JSON.parse(File.read('data/document_inclusion_list.json'))
        matched_local_documents = local_documents.select{|p| p['projectid'] == projectId}
        matched_local_documents
    end

    def get_h1_project_document_details(projectId,projectJson)
        project_documents = projectJson['document_link']
        static_projects = JSON.parse(File.read('data/document_exclusion_list.json'))
        static_projects = static_projects.select{ |p| p['project'] == projectId }
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
        oipa = RestClient.get  api_simple_log(settings.oipa_api_url + "activities/?format=json&related_activity_id=#{projectId}&page_size=50&fields=iati_identifier,title")
        project = JSON.parse(oipa)
        project = project['results']
    end

    def get_funding_project_count(projectId)
        begin
            #oipa = RestClient.get  api_simple_log(settings.oipa_api_url + "activities/#{projectId}/transactions/?format=json&transaction_type=1&fields=url")
            oipa = RestClient.get  api_simple_log(settings.oipa_api_url_solr + 'transaction?q=iati_identifier:'+projectId+' AND transaction_type:1&rows=1000')
            project = JSON.parse(oipa)
            project = project['response']['numFound']
        rescue
            puts 'API error for get_funding_project_count method'
            project = 0
        end
    end

    def get_funded_project_count(projectId)
        activityDetails = RestClient.get  api_simple_log(settings.oipa_api_url + "activities/#{projectId}/?format=json")
        activityDetails = JSON.parse(activityDetails)
        activityDetails = activityDetails['related_activities']
        projectIdentifierList = projectId + ','
        if(activityDetails.length > 0)
            activityDetails.each do |activity|
                begin
                    if(activity['type']['code'].to_i == 2)
                        projectIdentifierList = projectIdentifierList + activity['ref'] + ','
                    end
                rescue
                end
            end
        end
        projectIdentifierList = projectIdentifierList[0,projectIdentifierList.length-1]
        oipa = RestClient.get  api_simple_log(settings.oipa_api_url + "activities/?format=json&transaction_provider_activity=#{projectIdentifierList}&fields=url")
        project = JSON.parse(oipa)
        project = project['count']
    end

    def get_funding_project_details(projectId)
        fundingProjectsAPI = RestClient.get  api_simple_log(settings.oipa_api_url + "activities/#{projectId}/transactions/?format=json&transaction_type=1&page_size=1000" )
        fundingProjectsData = JSON.parse(fundingProjectsAPI)
    end

    def get_funded_project_details(projectId)
        response = getProjectIdentifierList(projectId)
        projectIdentifierList = response['projectIdentifierList']
        projectCount = RestClient.get  api_simple_log(settings.oipa_api_url + "activities/?format=json&transaction_provider_activity=#{projectIdentifierList}&page_size=1&fields=id&ordering=title")
        projectCount = JSON.parse(projectCount)
        projectCount = projectCount['count']
        pageSize = 10
        pages = (projectCount.to_f/pageSize.to_f).ceil
        fundedProjects = Array.new
        for a in 1..pages do
            tempProjects = RestClient.get  api_simple_log(settings.oipa_api_url + "activities/?format=json&transaction_provider_activity=#{projectIdentifierList}&page_size=#{pageSize}&fields=id,title,description,reporting_org,participating_org,activity_plus_child_aggregation,default_currency,aggregations,iati_identifier&ordering=title&page=#{a}")
            tempProjects = JSON.parse(tempProjects)
            tempProjects['results'].each do |i|
                begin
                    if(response['projectIdentifierListArray'].include?(i['iati_identifier'].to_s))
                    else
                        fundedProjects.push(i)
                    end
                rescue
                    puts i
                end
            end
        end
        projectsByKeys = {}
        fundedProjects.each do |p|
            projectsByKeys[p['iati_identifier']] = {}
            projectsByKeys[p['iati_identifier']] = p
        end
        puts 'funded project details grabbed'
        projectsByKeys
    end

    def getProjectIdentifierList(projectId)
        #activityDetails = RestClient.get  api_simple_log(settings.oipa_api_url + "activities/#{projectId}/?format=json&fields=related_activity")
        activityDetails = RestClient.get  api_simple_log(settings.oipa_api_url_solr + 'activity?q=iati_identifier:'+projectId+'&fl=related_activity')
        activityDetails = JSON.parse(activityDetails)
        if activityDetails['response']['docs'].first.has_key?('related_activity')
            activityDetails = activityDetails['response']['docs'].first['related_activity']
        else
            activityDetails = []
        end
        projectIdentifierList = projectId + ','
        projectIdentifierListArray = Array.new
        projectIdentifierListArray.push(projectId.to_s)
        if(activityDetails.length > 0)
            activityDetails.each do |activity|
                activity = JSON.parse(activity)
                begin
                    if(activity['type']['code'].to_i == 2)
                        projectIdentifierList = projectIdentifierList + activity['ref'] + ' '
                        projectIdentifierListArray.push(activity['ref'].to_s)
                    end
                rescue
                end
            end
        end
        projectIdentifierList = projectIdentifierList[0,projectIdentifierList.length-1]
        combinedResponse = {}
        combinedResponse['projectIdentifierList'] = projectIdentifierList
        combinedResponse['projectIdentifierListArray'] = projectIdentifierListArray
        combinedResponse
    end

    def get_transaction_details(projectId,transactionType)
        if is_dfid_project(projectId) then
            oipaTransactionURL = settings.oipa_api_url + "transactions/?format=json&related_activity_id=#{projectId}&transaction_type=#{transactionType}&fields=aggregations,activity,description,provider_organisation,provider_activity,receiver_organisation,transaction_date,transaction_type,value,currency"
            #oipaTransactionsJSON = RestClient.get  api_simple_log(settings.oipa_api_url + "transactions/?format=json&related_activity_id=#{projectId}&transaction_type=#{transactionType}&page_size=1&fields=aggregations,activity,description,provider_organisation,provider_activity,receiver_organisation,transaction_date,transaction_type,value,currency")
        else
            oipaTransactionURL = settings.oipa_api_url + "transactions/?format=json&iati_identifier=#{projectId}&transaction_type=#{transactionType}&fields=aggregations,activity,description,provider_organisation,receiver_organisation,transaction_date,transaction_type,value,currency"
            #oipaTransactionsJSON = RestClient.get  api_simple_log(settings.oipa_api_url + "transactions/?format=json&iati_identifier=#{projectId}&transaction_type=#{transactionType}&page_size=1&fields=aggregations,activity,description,provider_organisation,receiver_organisation,transaction_date,transaction_type,value,currency")
        end
        # Get the initial transaction count based on above API call
        initialPull = JSON.parse(RestClient.get oipaTransactionURL + "&page_size=20")
        transactionsJSON = initialPull['results']
        # Process remaining transactions if transaction count is more than 20
        if (initialPull['count'] > 20)
            pages = (initialPull['count'].to_f/20).ceil
            for page in 2..pages do
              tempData = JSON.parse(RestClient.get  oipaTransactionURL + "&page_size=20&page=#{page}")
              tempData['results'].each do |item|
                transactionsJSON.push(item)
              end
            end
        end
        # Filter out wrong transaction types
        transactions = transactionsJSON.select {|transaction| !transaction['transaction_type'].nil? }
    end

    def get_project_yearwise_budget(projectId)
        
        if is_dfid_project(projectId) then
            #oipa v3.1
            oipaYearWiseBudgets=RestClient.get  api_simple_log(settings.oipa_api_url + "budgets/aggregations/?format=json&reporting_organisation_identifier=#{settings.goverment_department_ids}&group_by=budget_period_start_quarter&aggregations=value&related_activity_id=#{projectId}&order_by=budget_period_start_year,budget_period_start_quarter")
        else
            #oipa v3.1
            oipaYearWiseBudgets=RestClient.get  api_simple_log(settings.oipa_api_url + "budgets/aggregations/?format=json&group_by=budget_period_start_quarter&aggregations=value&iati_identifier=#{projectId}&order_by=budget_period_start_year,budget_period_start_quarter")
        end

        yearWiseBudgets=JSON.parse(oipaYearWiseBudgets)
        #oipa3.1
        projectBudgets=financial_year_wise_budgets(yearWiseBudgets['results'].select {|project| !project['value'].nil? },"P")
    end

    def dfid_complete_country_list
        staticCountriesList = JSON.parse(File.read('data/dfidCountries.json')).sort_by{ |k| k["name"]}
        current_first_day_of_financial_year = first_day_of_financial_year(DateTime.now)
        current_last_day_of_financial_year = last_day_of_financial_year(DateTime.now)
        oipaCountryProjectBudgetValuesJSON = RestClient.get  api_simple_log(settings.oipa_api_url + "budgets/aggregations/?format=json&reporting_organisation_identifier=#{settings.goverment_department_ids}&budget_period_start=#{current_first_day_of_financial_year}&budget_period_end=#{current_last_day_of_financial_year}&group_by=recipient_country&aggregations=count,value&order_by=recipient_country")
        countriesList = JSON.parse(oipaCountryProjectBudgetValuesJSON)
        countriesList = countriesList['results']
        countriesList.each do |country|
            tempCountryDetails = staticCountriesList.select{|sct| sct['code'] == country["recipient_country"]["code"]}
             if tempCountryDetails.length>0
                 country["recipient_country"]["name"] =  tempCountryDetails[0]['name']
             end
        end
        countriesList = countriesList.sort_by{|k| k["recipient_country"]["name"]}
        countriesList
    end

    def dfid_complete_country_list_region_wise_sorted
        countryWithRegions = Oj.load(File.read('data/all-region-sorted-countries.json'))
        countryHash = {}
        countryWithRegions.each do |data|
            if data['region'] != ''
                tempString = data['alpha-2'].to_s
                countryHash[tempString] = {}
                countryHash[tempString]['name'] = data['name']
                countryHash[tempString]['region'] = data['region']
                countryHash[tempString]['activeProjects'] = 0
            end
        end
        # if !countryHash.has_key?("TA")
        #     countryHash['TA'] = {}
        #     countryHash['TA']['name'] = "Tristan da Cunha"
        #     countryHash['TA']['region'] = "Africa"
        #     countryHash['TA']['activeProjects'] = 0
        # end
        staticCountriesList = JSON.parse(File.read('data/dfidCountries.json')).sort_by{ |k| k["name"]}
        current_first_day_of_financial_year = first_day_of_financial_year(DateTime.now)
        current_last_day_of_financial_year = last_day_of_financial_year(DateTime.now)
        #oipaCountryProjectBudgetValuesJSON = RestClient.get  api_simple_log(settings.oipa_api_url + "budgets/aggregations/?format=json&reporting_organisation_identifier=#{settings.goverment_department_ids}&budget_period_start=#{current_first_day_of_financial_year}&budget_period_end=#{current_last_day_of_financial_year}&group_by=recipient_country&aggregations=count,value&order_by=recipient_country&activity_status=1,2")
        oipaCountryProjectBudgetValuesJSON = RestClient.get  api_simple_log(settings.oipa_api_url_solr + 'budget?q=participating_org_ref:GB-* AND reporting_org_ref:('+settings.goverment_department_ids.gsub(","," OR ")+') AND budget_period_start_iso_date_f:['+current_first_day_of_financial_year.to_s+'T00:00:00Z TO *] AND budget_period_end_iso_date_f:[* TO '+current_last_day_of_financial_year.to_s+'T00:00:00Z] AND activity_status_code:(1 2)&json.facet={"items":{"type":"terms","field":"recipient_country_code","limit":-1,"facet":{"value":"sum(budget_value)","name":{"type":"terms","field":"recipient_country_name","limit":1},"region":{"type":"terms","field":"recipient_region_code","limit":1}}}}&rows=0')
        countriesList = JSON.parse(oipaCountryProjectBudgetValuesJSON)
        countriesList = countriesList['facets']['items']['buckets']
        countriesList.each do |country|
            tempCountryDetails = staticCountriesList.select{|sct| sct['code'] == country["val"]}
            if tempCountryDetails.length>0
                 country["name"]["buckets"][0]['val'] =  tempCountryDetails[0]['name']
             elsif country["val"].to_s == 'VG'
                country["name"]["buckets"][0]['val'] =  'Virgin Islands (British)'
             end
            tempCode = country['val'].to_s
            if countryHash.has_key?(tempCode)
                countryHash[tempCode]['activeProjects'] = country['count']
                countryHash[tempCode]['name'] = country["name"]["buckets"][0]['val']
            end
        end
        sortedCountries = {}
        countryHash.each do |country|
            tempRegion = country[1]['region'].to_s
            if !sortedCountries.has_key?(tempRegion)
                sortedCountries[tempRegion] = {}
            end
            sortedCountries[tempRegion][country[0]] = {}
            sortedCountries[tempRegion][country[0]]['name'] = country[1]['name']
            sortedCountries[tempRegion][country[0]]['activeProjects'] = country[1]['activeProjects']
        end
        sortedCountries
    end

    def dfid_country_map_data
        current_first_day_of_financial_year = first_day_of_financial_year(DateTime.now)
        current_last_day_of_financial_year = last_day_of_financial_year(DateTime.now)
        #OIPA V3.1
        #oipaCountryProjectBudgetValuesJSON = RestClient.get  api_simple_log(settings.oipa_api_url + "budgets/aggregations/?format=json&reporting_organisation_identifier=#{settings.goverment_department_ids}&budget_period_start=#{current_first_day_of_financial_year}&budget_period_end=#{current_last_day_of_financial_year}&group_by=recipient_country&aggregations=count,value&order_by=recipient_country")
        oipaCountryProjectBudgetValuesJSON = RestClient.get  api_simple_log(settings.oipa_api_url_solr + 'budget?q=participating_org_ref:GB-* AND reporting_org_ref:('+settings.goverment_department_ids.gsub(","," OR ")+') AND budget_period_start_iso_date_f:['+current_first_day_of_financial_year.to_s+'T00:00:00Z TO *] AND budget_period_end_iso_date_f:[* TO '+current_last_day_of_financial_year.to_s+'T00:00:00Z]&json.facet={"items":{"type":"terms","field":"recipient_country_code","limit":-1,"facet":{"value":"sum(budget_value)","name":{"type":"terms","field":"recipient_country_name","limit":1},"region":{"type":"terms","field":"recipient_region_code","limit":1}}}}&rows=0')
        projectBudgetValues = JSON.parse(oipaCountryProjectBudgetValuesJSON)
        projectBudgetValues = projectBudgetValues['facets']['items']['buckets']
        #oipaCountryProjectCountJSON = RestClient.get  api_simple_log(settings.oipa_api_url + "activities/aggregations/?format=json&hierarchy=1&group_by=recipient_country&aggregations=count&reporting_org_identifier=#{settings.goverment_department_ids}&activity_status=2")
        oipaCountryProjectCountJSON = RestClient.get  api_simple_log(settings.oipa_api_url_solr + 'activity?q=participating_org_ref:GB-*'+add_exclusions_to_solr()+' AND reporting_org_ref:('+settings.goverment_department_ids.gsub(","," OR ")+') AND activity_status_code:(2) AND hierarchy:(1)&json.facet={"items":{"type":"terms","field":"recipient_country_code","limit":-1,"facet":{"name":{"type":"terms","field":"recipient_country_name","limit":1},"region":{"type":"terms","field":"recipient_region_code","limit":1}}}}&rows=0')
        projectValues = JSON.parse(oipaCountryProjectCountJSON)
        projectCountValues = projectValues['facets']['items']['buckets']
        countriesList = JSON.parse(File.read('data/countries.json'))
        
        projectDataHash = {}
        projectCountValues.each do |project|
            if project["val"].to_s != 'UA'
                tempBudget = projectBudgetValues.find do |projectBudget|
                    projectBudget["val"].to_s == project["val"]
                end
                tempCountry = countriesList.find do |source|
                    source["code"].to_s == project["val"]
                end
                begin
                    projectDataHash[project["val"]] = {}
                    projectDataHash[project["val"]]["country"] = tempCountry["name"]
                    projectDataHash[project["val"]]["id"] = project["val"]
                    projectDataHash[project["val"]]["projects"] = project["count"]
                #OIPA V2.2
                #projectDataHash[project["recipient_country"]["code"]]["budget"] = tempBudget.nil? ? 0 : tempBudget["budget"]
                #OIPA V3.1
                    projectDataHash[project["val"]]["budget"] = tempBudget.nil? ? 0 : tempBudget["value"]
                    projectDataHash[project["val"]]["flag"] = '/images/flags/' + project["val"].downcase + '.png'
                rescue
                end
            end
        end
        finalOutput = Array.new
        finalOutput.push(projectDataHash.to_s.gsub("[", "").gsub("]", "").gsub("=>",":").gsub("}}, {","},"))
        finalOutput.push(projectDataHash)
        finalOutput
    end

    

    def get_h2Activity_title(h2Activities,h2ActivityId)
        if h2Activities.length>0 then
            h2Activity = h2Activities.select {|activity| activity['iati_identifier'] == h2ActivityId}.first
            h2Activity.blank? ? ('') : (h2Activity['title']['narrative'][0]['text'])
        else
            ""
        end        
    end

    def get_funding_project(projectId)
        begin
            fundingProjectDetailsJSON = RestClient.get  api_simple_log(settings.oipa_api_url + "activities/#{projectId}/?format=json&fields=all" )
            fundingProjectDetails = JSON.parse(fundingProjectDetailsJSON)
        rescue
            return ''
        end
    end

    def reporting_organisation(project)
        begin
            if project['reporting_org_narrative'].first == 'UK - Department for International Development (DFID)'
                organisation = 'UK - Foreign, Commonwealth and Development Office (FCDO)'
            else
                organisation = project['reporting_org_narrative'].first
            end
        rescue
            organisation = 'Not available'
        end
    end

    def get_policy_markers(projectID)
        #activityDetails = RestClient.get  api_simple_log(settings.oipa_api_url + "activities/#{projectID}/?format=json")
        activityDetails = RestClient.get  api_simple_log(settings.oipa_api_url_solr + 'activity?q=iati_identifier:'+projectID+'&fl=policy_marker')
        activityDetails = JSON.parse(activityDetails)
        if activityDetails['response']['docs'].first.has_key?('policy_marker')
            policyMarkers = activityDetails['response']['docs'].first['policy_marker']
            policyMarkers
        else
            policyMarkers = []
            policyMarkers
        end
        # if(policyMarkers.length == 0)
        #     tempIDList = getProjectIdentifierList(n)['projectIdentifierListArray']
        #     if(tempIDList.length > 0)///////////////////////////////////////////////
        #         projectIdentifierList = ''
        #         if(activityDetails.length > 0)
        #             tempIDList.each do |activity|
        #                 begin
        #                     if(activity['type']['code'].to_i == 2)
        #                         projectIdentifierList = activity['ref']
        #                         break
        #                     end
        #                 rescue
        #                     puts 'rescued'
        #                 end
        #             end
        #         end
        #         getH2LevelData = RestClient.get  api_simple_log(settings.oipa_api_url + "activities/#{projectIdentifierList}/?format=json")
        #         getH2LevelData = JSON.parse(getH2LevelData)
        #         getH2LevelData['policy_markers']
        #     else
        #         policyMarkers = []
        #         policyMarkers
        #     end
        # else
        #     policyMarkers
        # end
    end

    def get_implementing_orgs(projectId)
        if is_dfid_project(projectId) then
            implementingOrgsDetailsJSON = RestClient.get  api_simple_log(settings.oipa_api_url + "activities/#{projectId}/?format=json&fields=all")
        else
            #implementingOrgsDetailsJSON = RestClient.get  api_simple_log(settings.oipa_api_url + "activities/?format=json&hierarchy=1&id=#{projectId}&fields=participating_organisations")
            implementingOrgsDetailsJSON = RestClient.get  api_simple_log(settings.oipa_api_url + "activities/#{projectId}/?format=json&fields=all")
        end
        implementingOrgsDetails = JSON.parse(implementingOrgsDetailsJSON)
        implementingOrg=implementingOrgsDetails['participating_org']

        #implementingOrg = data.collect{ |activity| activity['participating_organisations'][2]}.uniq.compact
        #implementingOrg = implementingOrg.select{ |activity| activity['role']['code']=="4"}
        implementingOrgsList = []
        implementingOrg.select{|imp| imp["role"]["code"]=="4" }.each do |i|
            if i["narrative"].length > 0 then 
                implementingOrgsList << i["narrative"][0]["text"]
            end
        end
        implementingOrgsList = implementingOrgsList.uniq.sort
    end

    def get_project_sector_graph_data(projectId)
        # if is_dfid_project(projectId) then
        #     projectSectorGraphJSON = RestClient.get  api_simple_log(settings.oipa_api_url + "budgets/aggregations/?format=json&reporting_organisation_identifier=#{settings.goverment_department_ids}&hierarchy=2&related_activity_id=#{projectId}&group_by=sector&aggregations=value&order_by=-value&page_count=1000")
        # else
        #     projectSectorGraphJSON = RestClient.get  api_simple_log(settings.oipa_api_url + "budgets/aggregations/?format=json&activity_id=#{projectId}&group_by=sector&aggregations=value&order_by=-value&page_count=1000")
        # end
        projectSectorGraphJSON = RestClient.get  api_simple_log(settings.oipa_api_url_solr + 'budget?q=participating_org_ref:GB-* AND iati_identifier:('+getProjectIdentifierList(projectId)['projectIdentifierList']+')&json.facet={"items":{"type":"terms","field":"sector_code","limit":-1,"sort":"value desc","facet":{"value":"sum(budget_value)"}}}&rows=0')
        projectSectorGraph = JSON.parse(projectSectorGraphJSON)
        c3ReadyStackBarData = Array.new
        
        if projectSectorGraph['facets']['count'] > 0
            iatiSectorCodes = Oj.load(File.read('data/Sector.json'))
            projectSector= projectSectorGraph['facets']['items']['buckets']
            projectSector.each do |sector|
                sector['name'] = iatiSectorCodes['data'].select{|s| s['code'].to_i == sector['val'].to_i}[0]['name']
            end
            totalBudgets = projectSector.reduce(0) {|memo, t| memo + t['value'].to_f} 
            c3ReadyStackBarData[0] = ''
            c3ReadyStackBarData[1] = '['
            topFiveCounter = 0
            totalOtherBudget = 0
            projectSector.each do |sector|
                if topFiveCounter < 11
                    sectorGroupPercentage = (100*sector['value'].to_f/totalBudgets.to_f).round(2)
                    c3ReadyStackBarData[0].concat('["'+sector['name']+'",'+sectorGroupPercentage.to_s+"],")
                    c3ReadyStackBarData[1].concat('"'+sector['name']+'",')
                else
                    totalOtherBudget = totalOtherBudget + sector['value'].to_f
                end
                topFiveCounter = topFiveCounter + 1
            end
            if topFiveCounter > 10
                sectorGroupPercentage = (100*totalOtherBudget.to_f/totalBudgets.to_f).round(2)
                c3ReadyStackBarData[0].concat('["Other Sectors",'+sectorGroupPercentage.to_s+"],")
                c3ReadyStackBarData[1].concat('"Other Sectors",')
            end
            c3ReadyStackBarData[1].concat(']')
            puts 'sector data grabbed'
            return c3ReadyStackBarData
        else
            c3ReadyStackBarData[0] = '["No data available for this view",0]'
            c3ReadyStackBarData[1] = "['No data available for this view']"
            puts 'sector data grabbed'
            return c3ReadyStackBarData
        end
    end

    def get_project_budget(projectId)
        if is_dfid_project(projectId) then
            projectBudgetJSON = RestClient.get  api_simple_log(settings.oipa_api_url + "activities/aggregations/?format=json&reporting_organisation_identifier=#{settings.goverment_department_ids}&related_activity_id=#{projectId}&group_by=related_activity&aggregations=expenditure,disbursement,budget")
        else
            projectBudgetJSON = RestClient.get  api_simple_log(settings.oipa_api_url + "activities/aggregations/?format=json&id=#{projectId}&group_by=related_activity&aggregations=expenditure,disbursement,budget")
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
                #oipa v3.1
                actualBudgetJSON = RestClient.get  api_simple_log(settings.oipa_api_url + "budgets/aggregations/?format=json&reporting_organisation_identifier=#{settings.goverment_department_ids}&related_activity_id=#{projectId}&group_by=budget_period_start_quarter&aggregations=value")
                disbursementJSON = RestClient.get  api_simple_log(settings.oipa_api_url + "transactions/aggregations/?format=json&reporting_organisation_identifier=#{settings.goverment_department_ids}&related_activity_id=#{projectId}&group_by=transaction_date_quarter&aggregations=disbursement")
                expenditureJSON = RestClient.get  api_simple_log(settings.oipa_api_url + "transactions/aggregations/?format=json&reporting_organisation_identifier=#{settings.goverment_department_ids}&related_activity_id=#{projectId}&group_by=transaction_date_quarter&aggregations=expenditure")
                purchaseOfEquityJSON = RestClient.get  api_simple_log(settings.oipa_api_url + "transactions/aggregations/?format=json&reporting_organisation_identifier=#{settings.goverment_department_ids}&related_activity_id=#{projectId}&group_by=transaction_date_quarter&aggregations=purchase_of_equity")
            else
                #oipa v3.1
                actualBudgetJSON = RestClient.get  api_simple_log(settings.oipa_api_url + "budgets/aggregations/?format=json&activity_id=#{projectId}&group_by=budget_period_start_quarter&aggregations=value")
                disbursementJSON = RestClient.get  api_simple_log(settings.oipa_api_url + "transactions/aggregations/?format=json&iati_identifier=#{projectId}&group_by=transaction_date_quarter&aggregations=disbursement")
                expenditureJSON = RestClient.get  api_simple_log(settings.oipa_api_url + "transactions/aggregations/?format=json&iati_identifier=#{projectId}&group_by=transaction_date_quarter&aggregations=expenditure")
                purchaseOfEquityJSON = RestClient.get  api_simple_log(settings.oipa_api_url + "transactions/aggregations/?format=json&iati_identifier=#{projectId}&group_by=transaction_date_quarter&aggregations=purchase_of_equity")
            end

            actualBudget = JSON.parse(actualBudgetJSON)
            actualBudget = actualBudget['results'].select {|project| !project['value'].nil? }
            disbursement = JSON.parse(disbursementJSON)    
            disbursement = disbursement['results'].select {|project| !project['disbursement'].nil? }
            expenditure = JSON.parse(expenditureJSON)    
            expenditure = expenditure['results'].select {|project| !project['expenditure'].nil? }
            purchaseOfEquity = JSON.parse(purchaseOfEquityJSON)
            purchaseOfEquity = purchaseOfEquity['results'].select {|project| !project['purchase_of_equity'].nil? }

            actualBudgetPerFy = get_actual_budget_per_fy(actualBudget)
            disbursementPerFy = get_spend_budget_per_fy(disbursement,"disbursement")
            expenditurePerFy = get_spend_budget_per_fy(expenditure,"expenditure")
            purchaseOfEquityPerFy = get_spend_budget_per_fy(purchaseOfEquity,"purchase_of_equity")

            spendBudgetPerFy = (disbursementPerFy + expenditurePerFy + purchaseOfEquityPerFy).group_by { |item|
                item['fy']
            }.map { |fy, bs|
                {
                    "fy"    => fy,
                    "type"  => "spend",
                    "value" => bs.inject(0) { |v, item| v + item["value"].to_f.floor(2) },
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
        projectCode[0, 5] == "GB-1-" || projectCode[0, 9] == "GB-GOV-1-" || projectCode[0, 9] == "GB-GOV-3-"
    end

    def is_hmg_project(reportingOrgCode)
        reportingOrgCode.downcase.include? "gb-gov"
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

    def location_data_for_csv(projectId)
        #oipa = RestClient.get  api_simple_log(settings.oipa_api_url + "activities/#{projectId}/?format=json&fields=location,title")
        oipa = RestClient.get  api_simple_log(settings.oipa_api_url_solr + "/activity?q=iati_identifier:"+projectId+"&fl=title_narrative_first,location")
        project = JSON.parse(oipa)['response']['docs'].first
        locationArray = Array.new
        project['location'].each do |location|
            location = JSON.parse(location)
            locationHash = {}
            begin
                locationHash['IATI Identifier'] = location['iati_identifier']
            rescue
                locationHash['IATI Identifier'] = 'N/A'
            end
            begin
                locationHash['Activity Title'] = project['title_narrative_first']
            rescue
                locationHash['Activity Title'] = 'N/A'
            end
            begin
               locationHash['Location Reach'] = location['location_reach']['code'] 
            rescue
                locationHash['Location Reach'] = 'N/A'
            end
            begin
               locationHash['Location Name'] = location['name']['narrative'].first['text'] 
            rescue
                locationHash['Location Name'] = 'N/A'
            end
            begin
                locationHash['Location Description'] = location['description']['narrative'].first['text']
            rescue
                locationHash['Location Description'] = 'N/A'
            end
            begin
                locationHash['Administrative Vocabulary'] = location['administrative'].first['code']
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
        if locationArray.length > 0
            locationData = hash_to_csv(locationArray)
        else
            locationData = ''
        end
        locationData
    end

    def transaction_data_hash_table_for_csv(transactionsForCSV,transactionType,projID)
        if transactionType == '3'
            tempStorage = Array.new
            transactionsForCSV.sort{ |a,b| b['transaction_date']  <=> a['transaction_date'] }.each do |transaction|
                tempHash = {}
                project2 = get_h1_project_details(projID)
                if !transaction['receiver_organisation'].nil?
                    if transaction['receiver_organisation']['ref'] == 'Excluded' || transaction['receiver_organisation']['ref'] == 'Not available'
                        tempHash['Receiver Organisation'] = transaction['receiver_organisation']['narrative'][0]['text']
                    elsif transaction['receiver_organisation']['ref'] != ''
                        tempOrg = project2['participating_org'].select{|p| p['ref'].to_s == transaction['receiver_organisation']['ref'].to_s} 
                        if !tempOrg.nil? && tempOrg.length > 0
                           tempHash['Receiver Organisation'] = tempOrg[0]['narrative'][0]['text']
                        else
                            tempHash['Receiver Organisation'] = "N/A"
                        end
                    else
                        begin
                             tempHash['Receiver Organisation'] = transaction['receiver_organisation']['narrative'][0]['text']
                         rescue 
                            tempHash['Receiver Organisation'] = "N/A" 
                         end 
                    end 
                else
                    tempHash['Receiver Organisation'] = "N/A"
                end
                if !transaction['receiver_organisation'].nil?
                    if !transaction['receiver_organisation']['type'].nil?
                        tempHash['Organisation Type'] = transaction['receiver_organisation']['type']['name']
                    else
                        tempOrg = project2['participating_org'].select{|p| p['ref'].to_s == transaction['receiver_organisation']['ref'].to_s}
                        if !tempOrg.nil? && tempOrg.length > 0 && transaction['receiver_organisation']['ref'].to_s.length != 0 && transaction['receiver_organisation']['ref'].to_s != 'NULL'
                            tempHash['Organisation Type'] = tempOrg[0]['type']['name']
                        else
                            tempHash['Organisation Type'] = "N/A"    
                        end
                   end
                else
                   tempHash['Organisation Type'] = "N/A" 
                end
                if is_dfid_project(transaction['activity']['iati_identifier'])
                    tempHash['IATI Activity ID'] = transaction['activity']['iati_identifier']
                else
                    tempHash['IATI Activity ID'] = 'N/A'
                end
                tempHash['Date'] = Date.parse(transaction['transaction_date']).strftime("%d %b %Y")
                tempHash['Value'] = transaction['value']
                tempHash['Currency'] = transaction['currency']['code']
                tempStorage.push(tempHash)
            end
            tempTransactions = hash_to_csv(tempStorage)
        elsif transactionType == '2'
            tempStorage = Array.new
            transactionsForCSV.sort{ |a,b| b['transaction_date']  <=> a['transaction_date'] }.each do |transaction|
                tempHash = {}
                project2 = get_h1_project_details(projID)
                if !transaction['receiver_organisation'].nil?
                    if !transaction['receiver_organisation']['ref'] != ''
                        tempOrg = project2['participating_org'].select{|p| p['ref'].to_s == transaction['receiver_organisation']['ref'].to_s} 
                        if !tempOrg.nil? && tempOrg.length > 0
                           tempHash['Receiver Organisation'] = tempOrg[0]['narrative'][0]['text']
                        else
                            tempHash['Receiver Organisation'] = "N/A"
                        end
                    else 
                        tempHash['Receiver Organisation'] = "N/A" 
                    end 
                else
                    tempHash['Receiver Organisation'] = "N/A"
                end
                if !transaction['receiver_organisation'].nil?
                    if !transaction['receiver_organisation']['type'].nil?
                        tempHash['Organisation Type'] = transaction['receiver_organisation']['type']['name']
                    else
                        tempOrg = project2['participating_org'].select{|p| p['ref'].to_s == transaction['receiver_organisation']['ref'].to_s}
                        if !tempOrg.nil? && tempOrg.length > 0 && transaction['receiver_organisation']['ref'].to_s.length != 0 && transaction['receiver_organisation']['ref'].to_s != 'NULL'
                            tempHash['Organisation Type'] = tempOrg[0]['type']['name']
                        else
                            tempHash['Organisation Type'] = "N/A"    
                        end
                   end
                else
                   tempHash['Organisation Type'] = "N/A" 
                end
                #tempHash['Activity Description'] = get_h2Activity_title(h2Activities,transaction['activity']['iati_identifier'])
                if is_dfid_project(transaction['activity']['iati_identifier'])
                    tempHash['IATI Activity ID'] = transaction['activity']['iati_identifier']
                else
                    tempHash['IATI Activity ID'] = 'N/A'
                end
                tempHash['Date'] = Date.parse(transaction['transaction_date']).strftime("%d %b %Y")
                tempHash['Value'] = transaction['value']
                tempHash['Currency'] = transaction['currency']['code']
                tempStorage.push(tempHash)
            end
            tempTransactions = hash_to_csv(tempStorage)
        elsif transactionType == '1'
            tempStorage = Array.new
            transactionsForCSV.sort{ |a,b| b['transaction_date']  <=> a['transaction_date'] }.each do |transaction|
                tempHash = {}
                if !transaction['description'].nil?
                    tempHash['Activity Description'] = transaction['description']['narrative'][0]['text']
                else
                    tempHash['Activity Description'] = "N/A"
                end
                if transaction['provider_organisation'].nil?
                    tempHash['Provider'] = 'N/A'
                elsif transaction['provider_organisation']['narrative'][0].nil?
                    tempHash['Provider'] = 'N/A'
                else
                    tempHash['Provider'] = transaction['provider_organisation']['narrative'][0]['text']
                end
                tempHash['Date'] = Date.parse(transaction['transaction_date']).strftime("%d %b %Y")
                tempHash['Value'] = transaction['value']
                tempHash['Currency'] = transaction['currency']['code']
                tempStorage.push(tempHash)
            end
            tempTransactions = hash_to_csv(tempStorage)
        elsif transactionType == '0'
            project = get_h1_project_details(projID)
            tempStorage = Array.new
            transactionsForCSV.each do |transaction|
                tempHash = {}
                tempHash['Financial Year'] = transaction['fy']
                #tempHash['Value'] = transaction['value']
                tempHash['Value'] = transaction['value']
                tempHash['Currency'] = project['default_currency']['code']
                tempStorage.push(tempHash)
            end
            tempTransactions = hash_to_csv(tempStorage)
        else
            tempStorage = Array.new
            transactionsForCSV.sort{ |a,b| b['transaction_date']  <=> a['transaction_date'] }.each do |transaction|
                tempHash = {}
                if !transaction['description'].nil?
                    tempHash['Activity Description'] = transaction['description']['narrative'][0]['text']
                else
                    tempHash['Activity Description'] = "N/A"
                end
                #tempHash['Activity Description'] = transaction['description']
                if !transaction['receiver_organisation'].nil?
                    if transaction['receiver_organisation']['narrative'].length > 0 
                        tempHash['Receiver Organisation'] = transaction['receiver_organisation']['narrative'][0]['text']
                    else 
                        tempHash['Receiver Organisation'] = "N/A" 
                    end 
                else
                    tempHash['Receiver Organisation'] = "N/A"
                end
                if is_dfid_project(transaction['activity']['iati_identifier'])
                    tempHash['IATI Activity ID'] = transaction['activity']['iati_identifier']
                else
                    tempHash['IATI Activity ID'] = 'N/A'
                end
                tempHash['Date'] = Date.parse(transaction['transaction_date']).strftime("%d %b %Y")
                tempHash['Value'] = transaction['value']
                tempHash['Currency'] = transaction['currency']['code']
                tempStorage.push(tempHash)
            end
            tempTransactions = hash_to_csv(tempStorage)
        end
        tempTransactions
    end

    #Get a list of map markers for visualisation for project
    def getProjectMapMarkers(projectId)
        #rawMapMarkers = JSON.parse(RestClient.get  api_simple_log(settings.oipa_api_url + "activities/#{projectId}/?format=json&fields=location,title"))
        rawMapMarkers = JSON.parse(RestClient.get  api_simple_log(settings.oipa_api_url_solr + 'activity?q=iati_identifier:'+projectId+'&fl=location,title_narrative_first,location_point_pos,location_name_narrative_text'))['response']['docs'].first
        mapMarkers = Array.new
        if rawMapMarkers.has_key?('location')
            rawMapMarkers['location'].each_with_index do |val, i|
                begin
                    iati_identifier = JSON.parse(val)['iati_identifier']
                    location = rawMapMarkers['location_point_pos'][i].to_s.gsub("(",'').gsub(")","").split(",")
                    tempStorage = {}
                    tempStorage["geometry"] = {}
                    tempStorage['geometry']['type'] = 'Point'
                    tempStorage['geometry']['coordinates'] = Array.new
                    tempStorage['geometry']['coordinates'].push(location[0].to_f)
                    tempStorage['geometry']['coordinates'].push(location[1].to_f)
                    tempStorage['iati_identifier'] = iati_identifier
                    tempStorage['loc'] = rawMapMarkers['location_name_narrative_text'][i]
                    tempStorage['title'] = rawMapMarkers['title_narrative_first']
                    mapMarkers.push(tempStorage)
                rescue
                    puts 'Data missing in API response.'
                end
            end
        end
        ########
        # rawMapMarkers = rawMapMarkers['response']['docs'].first['location']
        # mapMarkers = Array.new
        # ar = 0
        # rawMapMarkers.each do |location|
        #     begin
        #         tempStorage = {}
        #         tempStorage["geometry"] = {}
        #         tempStorage['geometry']['type'] = 'Point'
        #         tempStorage['geometry']['coordinates'] = Array.new
        #         tempStorage['geometry']['coordinates'].push(location['point']['pos']['longitude'].to_f)
        #         tempStorage['geometry']['coordinates'].push(location['point']['pos']['latitude'].to_f)
        #         tempStorage['iati_identifier'] = location['iati_identifier']
        #         begin
        #             tempStorage['loc'] = location['name']['narrative'][0]['text']
        #         rescue
        #             tempStorage['loc'] = 'N/A'
        #         end
        #         begin
        #         tempStorage['title'] = projectTitle
        #         rescue
        #         tempStorage['title'] = 'N/A'
        #         end
        #         mapMarkers.push(tempStorage)
        #         ar = ar + 1
        #     rescue
        #         puts 'Data missing in API response.'
        #     end
        # end
        #########
        mapMarkers
    end
end

#helpers ProjectHelpers
