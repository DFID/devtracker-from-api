#require "helpers/codelists"
#require "helpers/lookups"


module ProjectHelpers

    
    include CodeLists
    include CommonHelpers

    def check_if_project_exists(projectId)
        begin
            solrConfig = Oj.load(File.read('data/solr-config.json'))
            if(solrConfig["Exclusions"]["projects"].length > 0)
                solrConfig['Exclusions']['projects'].each_with_index do |fieldToBeChecked, index|
                    if(projectId.to_s ==fieldToBeChecked.to_s)
                        halt 404, "Activity not found"
                    end
                end
            end
            oipa = RestClient.get  api_simple_log(settings.oipa_api_url + "activity?q=iati_identifier:#{projectId}&fl=recipient_country_code,participating_org_ref")
            response = Oj.load(oipa)
            # tempData = response['response']['docs'].first.has_key?('recipient_country_code') ? response['response']['docs'].first['recipient_country_code'].select{|a| a.to_s == 'UA'}.length() : 0
            # if(tempData != 0)
            #     halt 404, "Activity not found"
            # end
            isGovOrgPresent = false
            orgData = response['response']['docs'].first['participating_org_ref']
            orgData.each do |item|
                if item[0, 6] == "GB-GOV" || item[0, 4] == "GB-1"
                    isGovOrgPresent = true
                    break
                end
            end
            if !isGovOrgPresent
                halt 404, "Activity not found"
            end
        rescue => e
            halt 404, "Activity not found"
        end
        return true
    end

    def get_h1_project_detailsv2(projectId)
        oipa = RestClient.get  api_simple_log(settings.oipa_api_url + "activity/?q=iati_identifier:#{projectId}&fl=*")
        project = JSON.parse(oipa)['response']['docs'].first
        project
    end

    def get_h1_project_documents(projectId)
        oipa = RestClient.get  api_simple_log(settings.oipa_api_url + "activity/?q=iati_identifier:#{projectId}&fl=reporting_org_narrative,document_link_title_narrative_lang,document_link_url,document_link_title_narrative,document-link.category-codes-combined,iati_identifier,document_link_language_code,contact_info*,title_narrative_text,last_updated_datetime_f")
        project = JSON.parse(oipa)['response']['docs'].first
        project
    end
    
    def get_funded_by_organisations(project)
        #if(is_dfid_project(project['id']))
            if(is_hmg_project(project['reporting_org']['ref']))
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

    def get_participating_organisationsv2(project)
        if(is_hmg_project(project['reporting_org_ref']))
            participatingOrgs = {}
            participatingOrgs['Funding'] = []
            participatingOrgs['Accountable'] = []
            participatingOrgs['Extending'] = []
            participatingOrgs['Implementing'] = []
            if (project.has_key?('participating_org_ref'))
                project['participating_org_narrative'].each_with_index do |org, index|
                    if(project['participating_org_role'][index].to_i == 1)
                        participatingOrgs['Funding'].push(org)
                    elsif (project['participating_org_role'][index].to_i == 2)
                        participatingOrgs['Accountable'].push(org)
                    elsif (project['participating_org_role'][index].to_i == 3)
                        participatingOrgs['Extending'].push(org)
                    elsif (project['participating_org_role'][index].to_i == 4)
                        participatingOrgs['Implementing'].push(org)
                    end
                end
            end
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
            oipa = RestClient.get  api_simple_log(settings.oipa_api_url + "activities/#{projectId}/transactions/?format=json&transaction_type=1&fields=url")
            project = JSON.parse(oipa)
            project = project['count']
        rescue
            project = 0
        end
    end

    def get_funding_project_countv2(projectId)
        begin
            oipa = RestClient.get  api_simple_log(settings.oipa_api_url + "/activity/?q=iati_identifier:#{projectId}* AND transaction_type:1&fl=iati_identifier")
            project = JSON.parse(oipa)['response']['numFound']
        rescue
            project = 0
        end
    end

    def get_funded_project_countv2(projectId)
        begin
            oipa = RestClient.get  api_simple_log(settings.oipa_api_url + "/activity/?q=transaction_provider_org_provider_activity_id:#{projectId}* AND !iati_identifier:(#{projectId}*)&fl=iati_identifier&rows=1")
            project = JSON.parse(oipa)['response']['numFound']
        rescue
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
        fundingProjectsData = fundingProjectsData['results']
        begin
            fundingProjects=fundingProjectsData
            .group_by{|b| b['provider_organisation']['provider_activity_id'].to_s.strip}
            .map{|provider_activity_id, budgets, currency|
                summedBudgets = budgets.reduce(0) {|memo, budget| memo.to_f + budget['value'].to_f}
                [provider_activity_id, summedBudgets]}
            refinedFundingProjects = []
            fundingProjects.each do |item|
                if is_valid_project(item[0])
                    targetData = fundingProjectsData.select{|d| d['provider_organisation'].to_s == item[0].to_s}.first
                    apiData = RestClient.get  api_simple_log(settings.oipa_api_url + "activities/#{item[0]}/?format=json&fields=title,description,reporting_org,default_currency" )
                    apiData = JSON.parse(apiData)
                    begin
                        item.push(apiData['reporting_org']['narrative'][0]['text'])
                    rescue
                        item.push('N/A')
                    end
                    begin
                        item.push(apiData['title']['narrative'][0]['text'])
                    rescue
                        item.push('N/A')
                    end
                    begin
                        item.push(apiData['description'][0]['narrative'][0]['text'])
                    rescue
                        item.push('N/A')
                    end
                    begin
                        item[1] = Money.new(item[1].to_f.round(0)*100, apiData['default_currency']['code']).format(:no_cents_if_whole => true,:sign_before_symbol => false)
                    rescue
                        item[1] = Money.new(item[1].to_f.round(0)*100, 'GBP').format(:no_cents_if_whole => true,:sign_before_symbol => false)
                    end
                    refinedFundingProjects.push(item)
                end
            end
            refinedFundingProjects
        rescue
            []
        end
    end

    def get_funding_project_detailsv2(projectId)
        print(settings.oipa_api_url + "activity/?q=transaction_receiver_org_receiver_activity_id:#{projectId}*&fl=activity_aggregation_disbursement_value_gbp,reporting_org_narrative,activity_aggregation_incoming_funds_value,activity_aggregation_budget_value,default_currency,iati_identifier,title_narrative,description_narrative,participating_org_ref,participating_org_role&start=#{0}&rows=200")
        newApiCall = RestClient.get settings.oipa_api_url + "activity/?q=transaction_receiver_org_receiver_activity_id:#{projectId}*&fl=activity_aggregation_disbursement_value_gbp,reporting_org_narrative,activity_aggregation_incoming_funds_value,activity_aggregation_budget_value,default_currency,iati_identifier,title_narrative,description_narrative,&start=#{0}&rows=200"
		newApiCall = JSON.parse(newApiCall)
        pulledData = newApiCall['response']['docs']
        fundedProjects = Array.new
        pulledData.each do |data|
            if(data['iati_identifier'].to_s != projectId.to_s)
                tempData = {}
                tempData['iati_identifier'] = data['iati_identifier']
                tempData['reporting_org_title'] = data['reporting_org_narrative'].first
                tempData['title'] = data.has_key?('title_narrative') ? data['title_narrative'].first : 'N/A'
                tempData['description'] = data.has_key?('description_narrative') ? data['description_narrative'].first : 'N/A'
                # tempData['total_project_budget'] = data.has_key?('activity_aggregation_budget_value') ? Money.new(data['activity_aggregation_budget_value'].to_f.round(0)*100,data['default_currency']).format(:no_cents_if_whole => true,:sign_before_symbol => false) : '£0'
                tempData['total_funding'] = data.has_key?('activity_aggregation_budget_value') ? Money.new(data['activity_aggregation_budget_value'].to_f.round(0)*100,data['default_currency']).format(:no_cents_if_whole => true,:sign_before_symbol => false) : '£0'
                fundedProjects.push(tempData)
            end
        end
        projectsByKeys = {}
        fundedProjects.each do |p|
            projectsByKeys[p['iati_identifier']] = {}
            projectsByKeys[p['iati_identifier']] = p
        end
        projectsByKeys
        data = {}
        data['projectsByKeys'] = projectsByKeys
        data
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
        projectsByKeys
    end

    def get_funded_project_details_page(projectId, page, count)
        response = getProjectIdentifierList(projectId)
        projectIdentifierList = response['projectIdentifierList']
        fundedProjects = Array.new
        tempProjects = RestClient.get  api_simple_log(settings.oipa_api_url + "activities/?format=json&transaction_provider_activity=#{projectIdentifierList}&page_size=#{count}&fields=id,title,description,reporting_org,participating_org,activity_plus_child_aggregation,default_currency,aggregations,iati_identifier&ordering=title&page=#{page}")
        tempProjects = JSON.parse(tempProjects)
        tempProjects['results'].each do |i|
            begin
                if(response['projectIdentifierListArray'].include?(i['iati_identifier'].to_s))
                else
                    tdata = i
                    tdata['total_project_budget'] = 0.00
                    tdata['total_funding'] = 0.00
                    begin       
                        tdata['total_project_budget'] = Money.new(i['activity_plus_child_aggregation']['activity_children']['budget_value'].to_f.round(0)*100,if i['activity_plus_child_aggregation']['activity_children']['budget_currency'].nil? then i['default_currency']['code'] else i['activity_plus_child_aggregation']['activity_children']['budget_currency'] end).format(:no_cents_if_whole => true,:sign_before_symbol => false)
                    rescue
                        tdata['total_project_budget'] = 0.00
                    end
                    begin       
                        tdata['total_funding'] = Money.new(i['activity_plus_child_aggregation']['activity_children']['incoming_funds_value'].to_f.round(0)*100,if i['activity_plus_child_aggregation']['activity_children']['incoming_funds_currency'].nil? then i['default_currency']['code'] else i['activity_plus_child_aggregation']['activity_children']['incoming_funds_currency'] end).format(:no_cents_if_whole => true,:sign_before_symbol => false)
                    rescue
                        tdata['total_funding'] = 0.00
                    end
                    fundedProjects.push(i)
                end
            rescue
                puts i
            end
        end
        projectsByKeys = {}
        fundedProjects.each do |p|
            projectsByKeys[p['iati_identifier']] = {}
            projectsByKeys[p['iati_identifier']] = p
        end
        projectsByKeys
        data = {}
        data['projectsByKeys'] = projectsByKeys
        data['hasNext'] = tempProjects['next']
        data
    end

    def get_funded_project_details_pagev2(projectId, page, count)
        page = page.to_i - 1
        finalPage = page * count
        newApiCall = RestClient.get settings.oipa_api_url + "activity/?q=transaction_provider_org_provider_activity_id:#{projectId}* AND !iati_identifier:(#{projectId}*)&fl=reporting_org_narrative,activity_aggregation_incoming_funds_value,activity_aggregation_budget_value,default_currency,iati_identifier,title_narrative,description_narrative,participating_org_ref,participating_org_role&start=#{finalPage}&rows=#{count}"
		newApiCall = JSON.parse(newApiCall)
        pulledData = newApiCall['response']['docs']
        fundedProjects = Array.new
        pulledData.each do |data|
            if(data['iati_identifier'].to_s != projectId.to_s)
                tempData = {}
                tempData['iati_identifier'] = data['iati_identifier']
                tempData['reporting_org_title'] = data['reporting_org_narrative'].first
                tempData['title'] = data.has_key?('title_narrative') ? data['title_narrative'].first : 'N/A'
                tempData['description'] = data.has_key?('description_narrative') ? data['description_narrative'].first : 'N/A'
                tempData['total_project_budget'] = data.has_key?('activity_aggregation_budget_value') ? Money.new(data['activity_aggregation_budget_value'].to_f.round(0)*100,data['default_currency']).format(:no_cents_if_whole => true,:sign_before_symbol => false) : '£0'
                tempData['total_funding'] = data.has_key?('activity_aggregation_incoming_funds_value') ? Money.new(data['activity_aggregation_incoming_funds_value'].to_f.round(0)*100,data['default_currency']).format(:no_cents_if_whole => true,:sign_before_symbol => false) : '£0'
                fundedProjects.push(tempData)
            end
        end
        projectsByKeys = {}
        fundedProjects.each do |p|
            projectsByKeys[p['iati_identifier']] = {}
            projectsByKeys[p['iati_identifier']] = p
        end
        projectsByKeys
        data = {}
        data['projectsByKeys'] = projectsByKeys
        data
    end

    def getProjectIdentifierList(projectId)
        activityDetails = RestClient.get  api_simple_log(settings.oipa_api_url + "activities/#{projectId}/?format=json&fields=related_activity")
        activityDetails = JSON.parse(activityDetails)
        activityDetails = activityDetails['related_activity']
        projectIdentifierList = projectId + ','
        projectIdentifierListArray = Array.new
        projectIdentifierListArray.push(projectId.to_s)
        if(activityDetails.length > 0)
            activityDetails.each do |activity|
                begin
                    if(activity['type']['code'].to_i == 2)
                        projectIdentifierList = projectIdentifierList + activity['ref'] + ','
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

    def get_transaction_count(projectId)
        if is_dfid_project(projectId) then
            oipaTransactionURL = settings.oipa_api_url + "transactions/?format=json&related_activity_id=#{projectId}&transaction_type=1,2,3,4,5,6,8&fields=aggregations,activity,description,provider_organisation,provider_activity,receiver_organisation,transaction_date,transaction_type,value,currency&page_size=1"
            #oipaTransactionsJSON = RestClient.get  api_simple_log(settings.oipa_api_url + "transactions/?format=json&related_activity_id=#{projectId}&transaction_type=#{transactionType}&page_size=1&fields=aggregations,activity,description,provider_organisation,provider_activity,receiver_organisation,transaction_date,transaction_type,value,currency")
        else
            oipaTransactionURL = settings.oipa_api_url + "transactions/?format=json&iati_identifier=#{projectId}&transaction_type=1,2,3,4,5,6,8&fields=aggregations,activity,description,provider_organisation,receiver_organisation,transaction_date,transaction_type,value,currency&page_size=1"
            #oipaTransactionsJSON = RestClient.get  api_simple_log(settings.oipa_api_url + "transactions/?format=json&iati_identifier=#{projectId}&transaction_type=#{transactionType}&page_size=1&fields=aggregations,activity,description,provider_organisation,receiver_organisation,transaction_date,transaction_type,value,currency")
        end
        # Get the initial transaction count based on above API call
        initialPull = JSON.parse(RestClient.get oipaTransactionURL)
        initialPull['count']
    end

    def get_transaction_countv2(projectId)
        oipaTransactionURL = settings.oipa_api_url + "/activity/?q=iati_identifier:#{projectId}*&fl=transaction_ref"
        tCount = 0
        initialPull = JSON.parse(RestClient.get oipaTransactionURL)['response']['numFound']
        # initialPull.each do |item|
        #     if(item.has_key?('transaction_ref'))
        #         if (item['transaction_ref'].count > 0)
        #             tCount = 1
        #             break
        #         end
        #     end
        # end
        if initialPull.to_i > 0
            tCount = 1
        end
        tCount
    end

    def get_transaction_total(projectId,transactionType, currency)
        if is_dfid_project(projectId) then
            puts 'This is a FCDO project'
            oipaTransactionURL = settings.oipa_api_url + "transactions/?format=json&related_activity_id=#{projectId}&transaction_type=#{transactionType}&fields=aggregations,activity,transaction_date,transaction_type,value,currency"
            #oipaTransactionsJSON = RestClient.get  api_simple_log(settings.oipa_api_url + "transactions/?format=json&related_activity_id=#{projectId}&transaction_type=#{transactionType}&page_size=1&fields=aggregations,activity,description,provider_organisation,provider_activity,receiver_organisation,transaction_date,transaction_type,value,currency")
        else
            puts 'This is not a FCDO project'
            oipaTransactionURL = settings.oipa_api_url + "transactions/?format=json&iati_identifier=#{projectId}&transaction_type=#{transactionType}&fields=aggregations,activity,transaction_date,transaction_type,value,currency"
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
        totalAmount = 0.00
        transactions.each do |t|
            totalAmount = totalAmount + t['value'].to_f
        end
        begin
            data = Money.new(totalAmount.to_f.round(0)*100, currency).format(:no_cents_if_whole => true,:sign_before_symbol => false)
        rescue
            data = "£#{totalAmount}"
        end
        data
    end

    def get_transaction_details_page(projectId,transactionType, page, count)
        if is_dfid_project(projectId) then
            puts 'This is a FCDO project'
            oipaTransactionURL = settings.oipa_api_url + "transactions/?format=json&related_activity_id=#{projectId}&transaction_type=#{transactionType}&fields=aggregations,activity,description,provider_organisation,provider_activity,receiver_organisation,transaction_date,transaction_type,value,currency"
            #oipaTransactionsJSON = RestClient.get  api_simple_log(settings.oipa_api_url + "transactions/?format=json&related_activity_id=#{projectId}&transaction_type=#{transactionType}&page_size=1&fields=aggregations,activity,description,provider_organisation,provider_activity,receiver_organisation,transaction_date,transaction_type,value,currency")
        else
            oipaTransactionURL = settings.oipa_api_url + "transactions/?format=json&iati_identifier=#{projectId}&transaction_type=#{transactionType}&fields=aggregations,activity,description,provider_organisation,receiver_organisation,transaction_date,transaction_type,value,currency"
            #oipaTransactionsJSON = RestClient.get  api_simple_log(settings.oipa_api_url + "transactions/?format=json&iati_identifier=#{projectId}&transaction_type=#{transactionType}&page_size=1&fields=aggregations,activity,description,provider_organisation,receiver_organisation,transaction_date,transaction_type,value,currency")
        end
        # Get the initial transaction count based on above API call
        initialPull = JSON.parse(RestClient.get oipaTransactionURL + "&page_size=#{count}&page=#{page}")
        transactionsJSON = initialPull['results']
        # Filter out wrong transaction types
        transactions = transactionsJSON.select {|transaction| !transaction['transaction_type'].nil? }
        response = {}
        response['transactions'] = transactionsJSON.select {|transaction| !transaction['transaction_type'].nil? }
        response['hasNext'] = initialPull['next']
        response
    end

    def get_transaction_details_pagev2(projectId, transactionType, page, count)
        page = page.to_i - 1
        finalPage = page * count
        oipaTransactionURL = settings.oipa_api_url + "activity/?q=iati_identifier:#{projectId}* AND transaction_type:#{transactionType}&fl=json.transaction,default-currency,iati-identifier,reporting_org_ref,reporting_org_narrative,participating_org_ref,participating_org_type,transaction_type,transaction_date_iso_date,transaction_value,transaction_description_narrative,transaction_provider_org_provider_activity_id,transaction_receiver_org_ref,transaction_receiver_org_narrative,transaction_value_currency,activity_aggregation_commitment_value,activity_aggregation_commitment_value_gbp,activity_aggregation_disbursement_value_gbp,activity_aggregation_expenditure_value_gbp&start=#{finalPage}&rows=#{count}"
        if transactionType.to_i == 2
            puts oipaTransactionURL
            puts (page.to_i*count.to_i)
        end
        orgTypes = JSON.parse(File.read('data/custom-codes/OrganisationType.json'))['data']
        # Get the initial transaction count based on above API call
        initialPull = JSON.parse(RestClient.get oipaTransactionURL)
        transactionsJSON = initialPull['response']['docs']
        finalTransactions = []
        transactionsJSON.each do |activity|
            if activity.has_key?('json.transaction')
                begin
                    activity['json.transaction'].each do |t|
                        t = JSON.parse(t)
                        if t['transaction-type']['code'].to_i == transactionType.to_i
                            tempTransaction = {}
                            receiverOrgType = ''
                            #currency = activity.has_key?('default-currency') ? activity['default-currency'] : 'GBP'
                            currency = t.has_key?('value.currency') ? t['value.currency'] : 'GBP'
                            if t.has_key?('receiver-org')
                                if t['receiver-org'].has_key?('type')
                                    begin
                                        x = orgTypes.select{|s| s['code'].to_i == t['receiver-org']['type'].to_i}.first
                                        receiverOrgType = x['name']
                                    rescue
                                        receiverOrgType = 'N/A'
                                    end
                                else
                                    receiverOrgType = 'N/A'
                                end
                            else
                                receiverOrgType = 'N/A'
                            end
                            tempTransaction['receiver_org_type'] = receiverOrgType
                            tempTransaction['value'] = Money.new(t['value'].to_f.round(0)*100, currency).format(:no_cents_if_whole => true,:sign_before_symbol => false)
                            tempTransaction['valueNoCurrency'] = t['value'].to_f
                            tempTransaction['receiver_org_title'] = t.has_key?('receiver-org') ? t['receiver-org']['narrative'] : 'N/A'
                            tempTransaction['transaction_date'] = t.has_key?('transaction-date') ? t['transaction-date']['iso-date'] : Time.now.iso8601
                            tempTransaction['description'] = t.has_key?('description') ? t['description']['narrative'] : 'N/A'
                            tempTransaction['iati_identifier'] = activity['iati-identifier']
                            tempTransaction['provider_org'] = t.has_key?('provider-org') ? t['provider-org']['ref'] : 'N/A'
                            tempTransaction['provider_activity_id'] = t.has_key?('provider-org') ? t['provider-org']['provider-activity-id'] : 'N/A'
                            tempTransaction['receiver_activity_id'] = begin t['receiver-org'].has_key?('receiver-activity-id') ? t['receiver-org']['receiver-activity-id'] : 'N/A' rescue 'N/A' end
                            finalTransactions.push(tempTransaction)
                        end
                    end
                rescue
                    puts activity['iati-identifier']
                    puts(oipaTransactionURL)
                end
            end
        end
        # Filter out wrong transaction types
        response = {}
        response['transactions'] = finalTransactions
        response['hasNext'] = if initialPull['response']['numFound'].to_i < ((page.to_i+1)*count.to_i) then false else true end
        response
    end

    def get_transaction_totalv2(projectId,transactionType)
        totalTransactionValue = 0
        count = 20
        page = 1
        page = page.to_i - 1
        finalPage = page * count
        #initialPull = oipaTransactionURL = settings.oipa_api_url + "activity/?q=iati_identifier:#{projectId}* AND transaction_type:#{transactionType}&fl=json.transaction,default-currency,iati-identifier,reporting_org_ref,reporting_org_narrative,participating_org_ref,participating_org_type,transaction_type,transaction_date_iso_date,transaction_value,transaction_description_narrative,transaction_provider_org_provider_activity_id,transaction_receiver_org_ref,transaction_receiver_org_narrative,transaction_value_currency,activity_aggregation_commitment_value,activity_aggregation_commitment_value_gbp,activity_aggregation_disbursement_value_gbp,activity_aggregation_expenditure_value_gbp&start=0&rows=#{count}"
        oipaTransactionURL = settings.oipa_api_url + "activity/?q=iati_identifier:#{projectId}* AND transaction_type:#{transactionType}&fl=json.transaction,default-currency,iati-identifier,reporting_org_ref,reporting_org_narrative,participating_org_ref,participating_org_type,transaction_type,transaction_date_iso_date,transaction_value,transaction_description_narrative,transaction_provider_org_provider_activity_id,transaction_receiver_org_ref,transaction_receiver_org_narrative,transaction_value_currency,activity_aggregation_commitment_value,activity_aggregation_commitment_value_gbp,activity_aggregation_disbursement_value_gbp,activity_aggregation_expenditure_value_gbp&start=0&rows=#{count}"
        orgTypes = JSON.parse(File.read('data/custom-codes/OrganisationType.json'))['data']
        looper = settings.oipa_api_url + "activity/?q=iati_identifier:#{projectId}* AND transaction_type:#{transactionType}&fl=json.transaction,default-currency,iati-identifier,reporting_org_ref,reporting_org_narrative,participating_org_ref,participating_org_type,transaction_type,transaction_date_iso_date,transaction_value,transaction_description_narrative,transaction_provider_org_provider_activity_id,transaction_receiver_org_ref,transaction_receiver_org_narrative,transaction_value_currency,activity_aggregation_commitment_value,activity_aggregation_commitment_value_gbp,activity_aggregation_disbursement_value_gbp,activity_aggregation_expenditure_value_gbp&start=0&rows=#{count}"
        # Get the initial transaction count based on above API call
        initialPull = JSON.parse(RestClient.get oipaTransactionURL)
        numOTransactions = initialPull['response']['numFound'].to_i
        transactionsJSON = initialPull['response']['docs']
        if (numOTransactions > count)
            currency = transactionsJSON.first.has_key?('default_currency') ? transactionsJSON.first['default_currency'] : 'GBP'
            pages = (numOTransactions.to_f/count).ceil
            for p in 2..pages do
                p = p - 1
                finalPage = p * count
                tempData = JSON.parse(RestClient.get settings.oipa_api_url + "activity/?q=iati_identifier:#{projectId}* AND transaction_type:#{transactionType}&fl=json.transaction,default-currency,iati-identifier,reporting_org_ref,reporting_org_narrative,participating_org_ref,participating_org_type,transaction_type,transaction_date_iso_date,transaction_value,transaction_description_narrative,transaction_provider_org_provider_activity_id,transaction_receiver_org_ref,transaction_receiver_org_narrative,transaction_value_currency,activity_aggregation_commitment_value,activity_aggregation_commitment_value_gbp,activity_aggregation_disbursement_value_gbp,activity_aggregation_expenditure_value_gbp&start=#{finalPage}&rows=#{count}")
                tempData = tempData['response']['docs']
                tempData.each do |item|
                    transactionsJSON.push(item)
                end
            end
        end
        transactionsJSON.each do |activity|
            if activity.has_key?('json.transaction')
                activity['json.transaction'].each do |t|
                    t = JSON.parse(t)
                    if t['transaction-type']['code'].to_i == transactionType.to_i
                        totalTransactionValue = totalTransactionValue + t['value'].to_f
                    end
                end
            end
        end
        totalTransactionValue = Money.new(totalTransactionValue.to_f.round(0)*100, currency).format(:no_cents_if_whole => true,:sign_before_symbol => false)
        ####
        totalTransactionValue
    end

    def spendToDatev2(projectId)
        spendToDate = 0
        count = 20
        page = 1
        page = page.to_i - 1
        finalPage = page * count
        oipaTransactionURL = settings.oipa_api_url + "activity/?q=iati_identifier:#{projectId}* AND transaction_type:(3 OR 4 OR 8) AND hierarchy:(1 OR 2)&fl=json.transaction,default-currency,iati-identifier,reporting_org_ref,reporting_org_narrative,participating_org_ref,participating_org_type,transaction_type,transaction_date_iso_date,transaction_value,transaction_description_narrative,transaction_provider_org_provider_activity_id,transaction_receiver_org_ref,transaction_receiver_org_narrative,transaction_value_currency,activity_aggregation_commitment_value,activity_aggregation_commitment_value_gbp,activity_aggregation_disbursement_value_gbp,activity_aggregation_expenditure_value_gbp&start=0&rows=#{count}"
        orgTypes = JSON.parse(File.read('data/custom-codes/OrganisationType.json'))['data']
        looper = settings.oipa_api_url + "activity/?q=iati_identifier:#{projectId}* AND transaction_type:(3 OR 4 OR 8) AND hierarchy:(1 OR 2)&fl=json.transaction,default-currency,iati-identifier,reporting_org_ref,reporting_org_narrative,participating_org_ref,participating_org_type,transaction_type,transaction_date_iso_date,transaction_value,transaction_description_narrative,transaction_provider_org_provider_activity_id,transaction_receiver_org_ref,transaction_receiver_org_narrative,transaction_value_currency,activity_aggregation_commitment_value,activity_aggregation_commitment_value_gbp,activity_aggregation_disbursement_value_gbp,activity_aggregation_expenditure_value_gbp&start=0&rows=#{count}"
        # Get the initial transaction count based on above API call
        initialPull = JSON.parse(RestClient.get oipaTransactionURL)
        numOTransactions = initialPull['response']['numFound'].to_i
        transactionsJSON = initialPull['response']['docs']
        if (numOTransactions > count)
            currency = transactionsJSON.first.has_key?('default_currency') ? transactionsJSON.first['default_currency'] : 'GBP'
            pages = (numOTransactions.to_f/count).ceil
            for p in 2..pages do
                p = p - 1
                finalPage = p * count
                tempData = JSON.parse(RestClient.get settings.oipa_api_url + "activity/?q=iati_identifier:#{projectId}* AND transaction_type:(3 OR 4 OR 8) AND hierarchy:(1 OR 2)&fl=json.transaction,default-currency,iati-identifier,reporting_org_ref,reporting_org_narrative,participating_org_ref,participating_org_type,transaction_type,transaction_date_iso_date,transaction_value,transaction_description_narrative,transaction_provider_org_provider_activity_id,transaction_receiver_org_ref,transaction_receiver_org_narrative,transaction_value_currency,activity_aggregation_commitment_value,activity_aggregation_commitment_value_gbp,activity_aggregation_disbursement_value_gbp,activity_aggregation_expenditure_value_gbp&start=#{finalPage}&rows=#{count}")
                tempData = tempData['response']['docs']
                transactionsJSON.concat(tempData)
            end
        end
        if numOTransactions > 0
            transactionsJSON.each do |activity|
                #begin
                if activity.is_a?(Hash)
                    if activity.has_key?('json.transaction')
                        activity['json.transaction'].each do |t|
                            t = JSON.parse(t)
                            if t['transaction-type']['code'].to_i == 3 || t['transaction-type']['code'].to_i == 4 || t['transaction-type']['code'].to_i == 8
                                spendToDate = spendToDate + t['value'].to_f
                            end
                        end
                    else
                        print('does not exist')
                    end
                end
            end
        end
        spendToDate
    end

    def get_transactionsv2(projectId,transactionType)
        count = 20
        page = 1
        page = page.to_i - 1
        finalPage = page * count
        #initialPull = oipaTransactionURL = settings.oipa_api_url + "activity/?q=iati_identifier:#{projectId}* AND transaction_type:#{transactionType}&fl=json.transaction,default-currency,iati-identifier,reporting_org_ref,reporting_org_narrative,participating_org_ref,participating_org_type,transaction_type,transaction_date_iso_date,transaction_value,transaction_description_narrative,transaction_provider_org_provider_activity_id,transaction_receiver_org_ref,transaction_receiver_org_narrative,transaction_value_currency,activity_aggregation_commitment_value,activity_aggregation_commitment_value_gbp,activity_aggregation_disbursement_value_gbp,activity_aggregation_expenditure_value_gbp&start=0&rows=#{count}"
        oipaTransactionURL = settings.oipa_api_url + "activity/?q=iati_identifier:#{projectId}* AND transaction_type:#{transactionType}&fl=json.transaction,default-currency,iati-identifier,reporting_org_ref,reporting_org_narrative,participating_org_ref,participating_org_type,transaction_type,transaction_date_iso_date,transaction_value,transaction_description_narrative,transaction_provider_org_provider_activity_id,transaction_receiver_org_ref,transaction_receiver_org_narrative,transaction_value_currency,activity_aggregation_commitment_value,activity_aggregation_commitment_value_gbp,activity_aggregation_disbursement_value_gbp,activity_aggregation_expenditure_value_gbp&start=0&rows=#{count}"
        orgTypes = JSON.parse(File.read('data/custom-codes/OrganisationType.json'))['data']
        looper = settings.oipa_api_url + "activity/?q=iati_identifier:#{projectId}* AND transaction_type:#{transactionType}&fl=json.transaction,default-currency,iati-identifier,reporting_org_ref,reporting_org_narrative,participating_org_ref,participating_org_type,transaction_type,transaction_date_iso_date,transaction_value,transaction_description_narrative,transaction_provider_org_provider_activity_id,transaction_receiver_org_ref,transaction_receiver_org_narrative,transaction_value_currency,activity_aggregation_commitment_value,activity_aggregation_commitment_value_gbp,activity_aggregation_disbursement_value_gbp,activity_aggregation_expenditure_value_gbp&start=0&rows=#{count}"
        # Get the initial transaction count based on above API call
        initialPull = JSON.parse(RestClient.get oipaTransactionURL)
        numOTransactions = initialPull['response']['numFound'].to_i
        transactionsJSON = initialPull['response']['docs']
        if (numOTransactions > count)
            currency = transactionsJSON.first.has_key?('default_currency') ? transactionsJSON.first['default_currency'] : 'GBP'
            pages = (numOTransactions.to_f/count).ceil
            for p in 2..pages do
                p = p - 1
                finalPage = p * count
                tempData = JSON.parse(RestClient.get settings.oipa_api_url + "activity/?q=iati_identifier:#{projectId}* AND transaction_type:#{transactionType}&fl=json.transaction,default-currency,iati-identifier,reporting_org_ref,reporting_org_narrative,participating_org_ref,participating_org_type,transaction_type,transaction_date_iso_date,transaction_value,transaction_description_narrative,transaction_provider_org_provider_activity_id,transaction_receiver_org_ref,transaction_receiver_org_narrative,transaction_value_currency,activity_aggregation_commitment_value,activity_aggregation_commitment_value_gbp,activity_aggregation_disbursement_value_gbp,activity_aggregation_expenditure_value_gbp&start=#{finalPage}&rows=#{count}")
                tempData = tempData['response']['docs']
                transactionsJSON.push(tempData)
            end
        end
        finalTransactions = []
        transactionsJSON.each do |activity|
            if activity.has_key?('json.transaction')
                activity['json.transaction'].each do |t|
                    t = JSON.parse(t)
                    if t['transaction-type']['code'].to_i == transactionType.to_i
                        tempTransaction = {}
                        receiverOrgType = ''
                        currency = activity.has_key?('default-currency') ? activity['default-currency'] : 'GBP'
                        receiverOrgRef = t.has_key?('receiver-org') ? t['receiver-org']['ref'] : 'N/A'
                        if !activity['participating_org_ref'].find_index(receiverOrgRef.to_s).nil?
                            begin
                                x = orgTypes.select{|s| s['code'].to_i == activity['participating_org_type'][activity['participating_org_ref'].find_index(receiverOrgRef.to_s)].to_i}.first
                                receiverOrgType = x['name']
                            rescue
                                receiverOrgType = 'N/A'
                            end    
                        else
                            receiverOrgType = 'N/A'
                        end
                        tempTransaction['receiver_org_type'] = receiverOrgType
                        tempTransaction['value'] = Money.new(t['value'].to_f.round(0)*100, currency).format(:no_cents_if_whole => true,:sign_before_symbol => false)
                        tempTransaction['valueNoCurrency'] = t['value'].to_f
                        tempTransaction['receiver_org_title'] = t.has_key?('receiver-org') ? t['receiver-org']['narrative'] : 'N/A'
                        tempTransaction['transaction_date'] = t.has_key?('transaction-date') ? t['transaction-date']['iso-date'] : Time.now.iso8601
                        tempTransaction['description'] = t.has_key?('description') ? t['description']['narrative'] : 'N/A'
                        tempTransaction['iati_identifier'] = activity['iati-identifier']
                        tempTransaction['provider_org'] = t.has_key?('provider-org') ? t['provider-org']['ref'] : 'N/A'
                        tempTransaction['provider_activity_id'] = t.has_key?('provider-org') ? t['provider-org']['provider-activity-id'] : 'N/A'
                        tempTransaction['receiver_activity_id'] = begin t['receiver-org'].has_key?('receiver-activity-id') ? t['receiver-org']['receiver-activity-id'] : 'N/A' rescue 'N/A' end
                        tempTransaction['currency'] = t.has_key?('value.currency') ? t['value.currency'] : 'GBP'
                        finalTransactions.push(tempTransaction)
                    end
                end
            end
        end
        ####
        finalTransactions
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

    def get_project_yearwise_budgetv2(projectId)
        programmeBudgets = RestClient.get api_simple_log(settings.oipa_api_url + "activity/?q=iati_identifier:#{projectId}*&fl=budget_value,default-currency,budget_period_start_iso_date,budget_period_end_iso_date,budget.period-start.quarter,budget.period-end.quarter&rows=100")

        yearWiseBudgets=JSON.parse(programmeBudgets)['response']['docs']
        #oipa3.1
        projectBudgets=financial_year_wise_budgetsv2(yearWiseBudgets,"P")
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

    def dfid_complete_country_list_region_wise_sortedv2
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
        # current_first_day_of_financial_year = first_day_of_financial_year(DateTime.now)
        # current_last_day_of_financial_year = last_day_of_financial_year(DateTime.now)
        newApiCall = settings.oipa_api_url + "activity?q=participating_org_ref:GB-GOV-* AND reporting_org_ref:(#{settings.goverment_department_ids.gsub(","," OR ")}) AND budget_period_start_iso_date:[#{settings.current_first_day_of_financial_year}T00:00:00Z TO *] AND budget_period_end_iso_date:[* TO #{settings.current_last_day_of_financial_year}T00:00:00Z] AND recipient_country_code:*&fl=recipient_country_code,budget_period_start_iso_date,budget_period_end_iso_date,budget_value_gbp,recipient_country_name,related_activity_type,related_activity_ref&rows=50000"
        projectTracker = []
        pulledData = RestClient.get newApiCall
        pulledData  = JSON.parse(pulledData)['response']['docs']
        finalData = []
        pulledData.each do |element|
            if (element.has_key?('recipient_country_code'))
                tempTotalBudget = 0
                #tempCountryDetails = staticCountriesList.select{|sct| sct['code'].to_s == element["recipient_country_code"].first.to_s}
                element['budget_period_start_iso_date'].each_with_index do |data, index|
                    if(data.to_datetime >= settings.current_first_day_of_financial_year && element['budget_period_end_iso_date'][index].to_datetime <= settings.current_last_day_of_financial_year)
                        tempTotalBudget = tempTotalBudget + element['budget_value_gbp'][index].to_f
                    end
                end
                # if tempCountryDetails.length>0
                #     country["recipient_country"]["name"] =  tempCountryDetails[0]['name']
                # elsif country["recipient_country"]["code"].to_s == 'VG'
                #    country["recipient_country"]["name"] =  'Virgin Islands (British)'
                # end
               tempCode = element['recipient_country_code'].first.to_s
               if countryHash.has_key?(tempCode)
                    if(element['hierarchy'] == 2)
                        if(!element['related_activity_type'].index('1').nil?)
                            if(!projectTracker.index(element['related_activity_ref'][element['related_activity_type'].index('1')].to_s).nil?)
                                countryHash[tempCode]['activeProjects'] = countryHash[tempCode]['activeProjects'] + 1
                                countryHash[tempCode]['name'] = element["recipient_country_name"]
                                projectTracker.push(element['related_activity_ref'][element['related_activity_type'].index('1')].to_s)
                            end
                        end
                    end
               end
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
        ###############
        #puts settings.oipa_api_url + "budgets/aggregations/?format=json&reporting_organisation_identifier=#{settings.goverment_department_ids}&budget_period_start=#{current_first_day_of_financial_year}&budget_period_end=#{current_last_day_of_financial_year}&group_by=recipient_country&aggregations=count,value&order_by=recipient_country&activity_status=1,2"
        # oipaCountryProjectBudgetValuesJSON = RestClient.get api_simple_log(settings.oipa_api_url + "budgets/aggregations/?format=json&reporting_organisation_identifier=#{settings.goverment_department_ids}&budget_period_start=#{current_first_day_of_financial_year}&budget_period_end=#{current_last_day_of_financial_year}&group_by=recipient_country&aggregations=count,value&order_by=recipient_country&activity_status=1,2")
        # countriesList = JSON.parse(oipaCountryProjectBudgetValuesJSON)
        # countriesList = countriesList['results']
        # countriesList.each do |country|
        #     tempCountryDetails = staticCountriesList.select{|sct| sct['code'] == country["recipient_country"]["code"]}
        #     if tempCountryDetails.length>0
        #          country["recipient_country"]["name"] =  tempCountryDetails[0]['name']
        #      elsif country["recipient_country"]["code"].to_s == 'VG'
        #         country["recipient_country"]["name"] =  'Virgin Islands (British)'
        #     end
        #     tempCode = country['recipient_country']['code'].to_s
        #     if countryHash.has_key?(tempCode)
        #         countryHash[tempCode]['activeProjects'] = country['count']
        #         countryHash[tempCode]['name'] = country["recipient_country"]["name"]
        #     end
        # end
        # sortedCountries = {}
        # countryHash.each do |country|
        #     tempRegion = country[1]['region'].to_s
        #     if !sortedCountries.has_key?(tempRegion)
        #         sortedCountries[tempRegion] = {}
        #     end
        #     sortedCountries[tempRegion][country[0]] = {}
        #     sortedCountries[tempRegion][country[0]]['name'] = country[1]['name']
        #     sortedCountries[tempRegion][country[0]]['activeProjects'] = country[1]['activeProjects']
        # end
        # sortedCountries
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
        oipaCountryProjectBudgetValuesJSON = RestClient.get api_simple_log(settings.oipa_api_url + "budgets/aggregations/?format=json&reporting_organisation_identifier=#{settings.goverment_department_ids}&budget_period_start=#{current_first_day_of_financial_year}&budget_period_end=#{current_last_day_of_financial_year}&group_by=recipient_country&aggregations=count,value&order_by=recipient_country&activity_status=1,2")
        countriesList = JSON.parse(oipaCountryProjectBudgetValuesJSON)
        countriesList = countriesList['results']
        countriesList.each do |country|
            tempCountryDetails = staticCountriesList.select{|sct| sct['code'] == country["recipient_country"]["code"]}
            if tempCountryDetails.length>0
                 country["recipient_country"]["name"] =  tempCountryDetails[0]['name']
             elsif country["recipient_country"]["code"].to_s == 'VG'
                country["recipient_country"]["name"] =  'Virgin Islands (British)'
             end
            tempCode = country['recipient_country']['code'].to_s
            if countryHash.has_key?(tempCode)
                countryHash[tempCode]['activeProjects'] = country['count']
                countryHash[tempCode]['name'] = country["recipient_country"]["name"]
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
        oipaCountryProjectBudgetValuesJSON = RestClient.get  api_simple_log(settings.oipa_api_url + "budgets/aggregations/?format=json&reporting_organisation_identifier=#{settings.goverment_department_ids}&budget_period_start=#{current_first_day_of_financial_year}&budget_period_end=#{current_last_day_of_financial_year}&group_by=recipient_country&aggregations=count,value&order_by=recipient_country")
        projectBudgetValues = JSON.parse(oipaCountryProjectBudgetValuesJSON)
        projectBudgetValues = projectBudgetValues['results']
        oipaCountryProjectCountJSON = RestClient.get  api_simple_log(settings.oipa_api_url + "activities/aggregations/?format=json&hierarchy=1&group_by=recipient_country&aggregations=count&reporting_org_identifier=#{settings.goverment_department_ids}&activity_status=2")
        projectValues = JSON.parse(oipaCountryProjectCountJSON)
        projectCountValues = projectValues['results']
        countriesList = JSON.parse(File.read('data/countries.json'))
        
        projectDataHash = {}
        projectCountValues.each do |project|
            if project["recipient_country"]["code"].to_s != 'UA2'
                tempBudget = projectBudgetValues.find do |projectBudget|
                    projectBudget["recipient_country"]["code"].to_s == project["recipient_country"]["code"]
                end
                tempCountry = countriesList.find do |source|
                    source["code"].to_s == project["recipient_country"]["code"]
                end
                begin
                    projectDataHash[project["recipient_country"]["code"]] = {}
                    projectDataHash[project["recipient_country"]["code"]]["country"] = tempCountry["name"]
                    projectDataHash[project["recipient_country"]["code"]]["id"] = project["recipient_country"]["code"]
                    projectDataHash[project["recipient_country"]["code"]]["projects"] = project["count"]
                #OIPA V2.2
                #projectDataHash[project["recipient_country"]["code"]]["budget"] = tempBudget.nil? ? 0 : tempBudget["budget"]
                #OIPA V3.1
                    projectDataHash[project["recipient_country"]["code"]]["budget"] = tempBudget.nil? ? 0 : tempBudget["value"]
                    projectDataHash[project["recipient_country"]["code"]]["flag"] = '/images/flags/' + project["recipient_country"]["code"].downcase + '.png'
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
            organisation = project['reporting_org']['narrative'][0]['text']
        rescue
            organisation = project['reporting_org']['type']['name']
        end
    end

    def reporting_organisationv2(project)
        begin
            organisation = project['reporting_org_narrative'].first
        rescue
            organisation = 'N/A'
        end
    end

    def get_policy_markers(projectID)
        activityDetails = RestClient.get  api_simple_log(settings.oipa_api_url + "activities/#{projectID}/?format=json")
        activityDetails = JSON.parse(activityDetails)
        policyMarkers = activityDetails['policy_markers']
        if(policyMarkers.length == 0)
            if(activityDetails['related_activities'].length > 0)
                activityDetails = activityDetails['related_activities']
                projectIdentifierList = ''
                if(activityDetails.length > 0)
                    activityDetails.each do |activity|
                        begin
                            if(activity['type']['code'].to_i == 2)
                                projectIdentifierList = activity['ref']
                                break
                            end
                        rescue
                            puts 'rescued'
                        end
                    end
                end
                getH2LevelData = RestClient.get  api_simple_log(settings.oipa_api_url + "activities/#{projectIdentifierList}/?format=json")
                getH2LevelData = JSON.parse(getH2LevelData)
                getH2LevelData['policy_markers']
            else
                policyMarkers = []
                policyMarkers
            end
        else
            policyMarkers
        end
    end

    def get_policy_markersv2(project)
        policyMarkers = []
        significances = Oj.load(File.read('data/PolicySignificance.json'))['data']
        begin
            if project.has_key?('policy_marker_code')
                project['policy_marker_narrative'].each_with_index do |item, index|
                    if project['policy_marker_significance'][index].to_i != 0
                        sig = significances.select{|status| status['code'].to_i == project['policy_marker_significance'][index].to_i}.first
                        marker = {}
                        marker['significance'] = sig['name']
                        marker['title'] = item
                        policyMarkers.push(marker)
                    end
                end
            end
        rescue
            puts('error')
        end
        policyMarkers
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

    def get_implementing_orgsv2(projectId)
        implementingOrgsDetailsJSON = RestClient.get  api_simple_log(settings.oipa_api_url + "activity/?q=iati-identifier:#{projectId}&rows=1&fl=participating_org_role,participating_org_narrative")
        implementingOrgsDetails = JSON.parse(implementingOrgsDetailsJSON)['response']['docs'].first

        implementingOrgsList = []
        if implementingOrgsDetails.has_key?('participating_org_narrative')
            implementingOrgsDetails['participating_org_role'].each_with_index do |item, index|
                if item.to_i == 4
                    implementingOrgsList << implementingOrgsDetails['participating_org_narrative'][index]
                end
            end
        end
        implementingOrgsList = implementingOrgsList.uniq.sort
    end

    def get_project_sector_graph_datav2(projectId)
        projectSectorGraphJSON = RestClient.get api_simple_log(settings.oipa_api_url + "activity/?q=iati-identifier:#{projectId}&fl=sector_code,sector_percentage,sector_narrative,activity_plus_child_aggregation_budget_value_gbp&rows=1")
        projectSectorGraph = JSON.parse(projectSectorGraphJSON)['response']['docs'].first
        c3ReadyStackBarData = Array.new
        if projectSectorGraph.has_key?('sector_code')
            if projectSectorGraph['sector_code'].length > 0
                if projectSectorGraph['sector_code'].length > 10
                    counter = 0
                    otherPercentage = 0
                    c3ReadyStackBarData[0] = ''
                    c3ReadyStackBarData[1] = '['
                    projectSectorGraph['sector_code'].each_with_index do |data, index|
                        if counter <=10
                            begin
                                narrative = projectSectorGraph['sector_narrative'][index].strip
                                percentage = projectSectorGraph['sector_percentage'][index]
                            rescue
                                narrative = 'N/A'
                                percentage = 0
                            end
                            c3ReadyStackBarData[0].concat('["'+narrative+'",'+percentage.to_s+"],")
                            c3ReadyStackBarData[1].concat('"'+narrative+'",')
                            counter = counter + 1
                        else
                            otherPercentage = otherPercentage + projectSectorGraph['sector_percentage'][index].to_f
                        end
                    end
                    c3ReadyStackBarData[0].concat('["Other Sectors",'+otherPercentage.to_s+"],")
                    c3ReadyStackBarData[1].concat('"Other Sectors",')
                    c3ReadyStackBarData[1].concat(']')
                    c3ReadyStackBarData
                else
                    c3ReadyStackBarData[0] = ''
                    c3ReadyStackBarData[1] = '['
                    projectSectorGraph['sector_code'].each_with_index do |data, index|
                        begin
                            narrative = begin projectSectorGraph['sector_narrative'][index].strip rescue data end
                            percentage = begin projectSectorGraph['sector_percentage'][index] rescue 100 end
                        rescue
                            narrative = 'N/A'
                            percentage = 0
                        end
                        if percentage.nil? || narrative.nil?
                            c3ReadyStackBarData[0].concat('["N/A",0],')
                        else
                            c3ReadyStackBarData[0].concat('["'+narrative+'",'+percentage.to_s+"],")
                        end
                        if narrative.nil?
                            c3ReadyStackBarData[1].concat('"N/A",')
                        else
                            c3ReadyStackBarData[1].concat('"'+narrative+'",')
                        end
                    end
                    c3ReadyStackBarData[1].concat(']')
                    c3ReadyStackBarData
                end
            else
                c3ReadyStackBarData[0] = '["No data available for this view",0]'
                c3ReadyStackBarData[1] = "['No data available for this view']"
                c3ReadyStackBarData    
            end
        else
            c3ReadyStackBarData[0] = '["No data available for this view",0]'
            c3ReadyStackBarData[1] = "['No data available for this view']"
            c3ReadyStackBarData
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
            puts expenditurePerFy
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

    def project_budget_per_fyv2(projectId)
        #Process budgets
        apiData = RestClient.get api_simple_log(settings.oipa_api_url + "activity/?q=iati-identifier:#{projectId}*&fl=budget.period-start.quarter,transaction.transaction-date.quarter,transaction_type,transaction_date_iso_date,transaction_value,budget_value_gbp,budget_period_start_iso_date,budget_period_end_iso_date,budget_value&start=0&rows=100")
        apiData = JSON.parse(apiData)['response']['docs']
        budgetHash = {}
        expenditureHash = {} #4
        disbursementHash = {} #3
        purchaseOfEquityHash = {} #8
        apiData.each do |activity|
            if activity.has_key?('budget_period_start_iso_date')
                activity['budget_period_start_iso_date'].each_with_index do |item, index|
                    t = Time.parse(item)
                    fy = if activity['budget.period-start.quarter'][index].to_i == 1 then t.year - 1 else t.year end
                    if budgetHash.has_key?(fy)
                        budgetHash[fy] = budgetHash[fy] + activity['budget_value'][index]
                    else
                        budgetHash[fy] = activity['budget_value'][index]
                    end
                end
            end
            if activity.has_key?('transaction_date_iso_date')
                activity['transaction_type'].each_with_index do |item, index|
                    if item.to_i == 3
                        t = Time.parse(activity['transaction_date_iso_date'][index])
                        fy = if activity['transaction.transaction-date.quarter'][index].to_i == 1 then t.year - 1 else t.year end
                        if disbursementHash.has_key?(fy)
                            disbursementHash[fy] = disbursementHash[fy] + activity['transaction_value'][index]
                        else
                            disbursementHash[fy] = activity['transaction_value'][index]
                        end
                    elsif item.to_i == 4
                        t = Time.parse(activity['transaction_date_iso_date'][index])
                        fy = if activity['transaction.transaction-date.quarter'][index].to_i == 1 then t.year - 1 else t.year end
                        if expenditureHash.has_key?(fy)
                            expenditureHash[fy] = expenditureHash[fy] + activity['transaction_value'][index]
                        else
                            expenditureHash[fy] = activity['transaction_value'][index]
                        end
                    elsif item.to_i == 8
                        t = Time.parse(activity['transaction_date_iso_date'][index])
                        fy = if activity['transaction.transaction-date.quarter'][index].to_i == 1 then t.year - 1 else t.year end
                        if purchaseOfEquityHash.has_key?(fy)
                            purchaseOfEquityHash[fy] = purchaseOfEquityHash[fy] + activity['transaction_value'][index]
                        else
                            purchaseOfEquityHash[fy] = activity['transaction_value'][index]
                        end
                    end
                end
            end
        end
        budgetHash.sort.to_h
        expenditureHash.sort.to_h
        disbursementHash.sort.to_h
        purchaseOfEquityHash.sort.to_h
        budgetArray = []
        expArray = []
        disbArray = []
        poeArray = []
        budgetHash.each do |key, val|
            b = {}
            b['fy'] = key
            b['type'] = 'budget'
            b['value'] = val
            budgetArray.push(b)
        end
        expenditureHash.each do |key, val|
            b = {}
            b['fy'] = key
            b['value'] = val
            expArray.push(b)
        end
        disbursementHash.each do |key, val|
            b = {}
            b['fy'] = key
            b['value'] = val
            disbArray.push(b)
        end
        purchaseOfEquityHash.each do |key, val|
            b = {}
            b['fy'] = key
            b['value'] = val
            poeArray.push(b)
        end
        begin #to mask errors in the return of the aggregation for some partner projects.
            spendBudgetPerFy = (disbArray + expArray + poeArray).group_by { |item|
                item['fy']
            }.map { |fy, bs|
                {
                    "fy"    => fy,
                    "type"  => "spend",
                    "value" => bs.inject(0) { |v, item| v + item["value"].to_f.floor(2) },
                }   
            }

            # merge the series and sort by financial year
            series = (spendBudgetPerFy + budgetArray).group_by { |item|
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

            range = if series.size < 900 then
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
        oipa = RestClient.get  api_simple_log(settings.oipa_api_url + "activities/#{projectId}/?format=json&fields=location,title")
        project = JSON.parse(oipa)
        locationArray = Array.new
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

    def transaction_data_hash_table_for_csvv2(transactionsForCSV,transactionType,projID)
        if transactionType == '3'
            tempStorage = Array.new
            transactionsForCSV.sort{ |a,b| b['transaction_date']  <=> a['transaction_date'] }.each do |transaction|
                tempHash = {}
                tempHash['Receiver Organisation'] = transaction['receiver_org_title']
                tempHash['Organisation Type'] = transaction['receiver_org_type']
                tempHash['IATI Activity ID'] = transaction['iati_identifier']
                tempHash['Date'] = Date.parse(transaction['transaction_date']).strftime("%d %b %Y")
                tempHash['Value'] = transaction['valueNoCurrency']
                tempHash['Currency'] = transaction['currency']
                tempStorage.push(tempHash)
            end
            tempTransactions = hash_to_csv(tempStorage)
        elsif transactionType == '2'
            tempStorage = Array.new
            transactionsForCSV.sort{ |a,b| b['transaction_date']  <=> a['transaction_date'] }.each do |transaction|
                tempHash = {}
                tempHash['Receiver Organisation'] = transaction['receiver_org_title']
                tempHash['Organisation Type'] = transaction['receiver_org_type']
                tempHash['IATI Activity ID'] = transaction['iati_identifier']
                tempHash['Date'] = Date.parse(transaction['transaction_date']).strftime("%d %b %Y")
                tempHash['Value'] = transaction['valueNoCurrency']
                tempHash['Currency'] = transaction['currency']
                tempStorage.push(tempHash)
            end
            tempTransactions = hash_to_csv(tempStorage)
        elsif transactionType == '1'
            tempStorage = Array.new
            transactionsForCSV.sort{ |a,b| b['transaction_date']  <=> a['transaction_date'] }.each do |transaction|
                tempHash = {}
                tempHash['Activity Description'] = transaction['description']
                tempHash['Provider'] = transaction['provider_org']
                tempHash['Date'] = Date.parse(transaction['transaction_date']).strftime("%d %b %Y")
                tempHash['Value'] = transaction['valueNoCurrency']
                tempHash['Currency'] = transaction['currency']
                tempStorage.push(tempHash)
            end
            tempTransactions = hash_to_csv(tempStorage)
        elsif transactionType == '0'
            project = get_h1_project_detailsv2(projID)
            tempStorage = Array.new
            transactionsForCSV.each do |transaction|
                tempHash = {}
                tempHash['Financial Year'] = transaction['fy']
                tempHash['Value'] = transaction['value']
                tempHash['Currency'] = project['default_currency']
                tempStorage.push(tempHash)
            end
            tempTransactions = hash_to_csv(tempStorage)
        else
            tempStorage = Array.new
            transactionsForCSV.sort{ |a,b| b['transaction_date']  <=> a['transaction_date'] }.each do |transaction|
                tempHash = {}
                tempHash['Activity Description'] = transaction['description']
                tempHash['Receiver Organisation'] = transaction['receiver_org_title']
                tempHash['IATI Activity ID'] = transaction['iati_identifier']
                tempHash['Date'] = Date.parse(transaction['transaction_date']).strftime("%d %b %Y")
                tempHash['Value'] = transaction['valueNoCurrency']
                tempHash['Currency'] = transaction['currency']
                tempStorage.push(tempHash)
            end
            tempTransactions = hash_to_csv(tempStorage)
        end
        tempTransactions
    end

    #Get a list of map markers for visualisation for project

    def getProjectMapMarkersv2(data)
        mapMarkers = Array.new
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
            end
        end
        mapMarkers
    end

    #----------To be redacted when merger with main solr branch will happen------------
    def dfid_country_map_data2
        current_first_day_of_financial_year = first_day_of_financial_year(DateTime.now)
        current_last_day_of_financial_year = last_day_of_financial_year(DateTime.now)
        #OIPA V3.1
        #oipaCountryProjectBudgetValuesJSON = RestClient.get  api_simple_log(settings.oipa_api_url + "budgets/aggregations/?format=json&reporting_organisation_identifier=#{settings.goverment_department_ids}&budget_period_start=#{current_first_day_of_financial_year}&budget_period_end=#{current_last_day_of_financial_year}&group_by=recipient_country&aggregations=count,value&order_by=recipient_country")
        oipaCountryProjectBudgetValuesJSON = RestClient.get  api_simple_log(settings.oipa_api_url + 'activity?q=participating_org_ref:GB-GOV-* AND reporting_org_ref:('+settings.goverment_department_ids.gsub(","," OR ")+') AND budget_period_start_iso_date:['+current_first_day_of_financial_year.to_s+'T00:00:00Z TO *] AND budget_period_end_iso_date:[* TO '+current_last_day_of_financial_year.to_s+'T00:00:00Z]&json.facet={"items":{"type":"terms","field":"recipient_country_code","limit":-1,"facet":{"value":"sum(budget_value)","name":{"type":"terms","field":"recipient_country_name","limit":1},"region":{"type":"terms","field":"recipient_region_code","limit":1}}}}&rows=0')
        projectBudgetValues = JSON.parse(oipaCountryProjectBudgetValuesJSON)
        projectBudgetValues = projectBudgetValues['facets']['items']['buckets']
        #oipaCountryProjectCountJSON = RestClient.get  api_simple_log(settings.oipa_api_url + "activities/aggregations/?format=json&hierarchy=1&group_by=recipient_country&aggregations=count&reporting_org_identifier=#{settings.goverment_department_ids}&activity_status=2")
        oipaCountryProjectCountJSON = RestClient.get  api_simple_log(settings.oipa_api_url + 'activity?q=participating_org_ref:GB-GOV-* AND reporting_org_ref:('+settings.goverment_department_ids.gsub(","," OR ")+') AND activity_status_code:(2) AND hierarchy:(1)&json.facet={"items":{"type":"terms","field":"recipient_country_code","limit":-1,"facet":{"name":{"type":"terms","field":"recipient_country_name","limit":1},"region":{"type":"terms","field":"recipient_region_code","limit":1}}}}&rows=0')
        projectValues = JSON.parse(oipaCountryProjectCountJSON)
        projectCountValues = projectValues['facets']['items']['buckets']
        countriesList = JSON.parse(File.read('data/countries.json'))
        
        projectDataHash = {}
        projectCountValues.each do |project|
            if project["val"].to_s != 'UA2'
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
                    projectDataHash[project["val"]]["budget"] = tempBudget.nil? ? 0 : tempBudget["value"].round(1)
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
end

#helpers ProjectHelpers
