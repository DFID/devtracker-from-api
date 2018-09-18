module CommonHelpers

  def get_current_total_budget(apiLink)
      currentTotalBudget= JSON.parse(apiLink)
  end

  def get_current_dfid_total_budget(apiLink)
      currentDfidTotalBudget= JSON.parse(apiLink)
  end

  def get_total_project(apiLink)
      totalProjects = JSON.parse(apiLink)
  end 

  def financial_year_wise_budgets(yearWiseBudgets,type)

      finYearWiseBudgets = get_actual_budget_per_fy(yearWiseBudgets)
      # determine what range to show
      #current_financial_year = first_day_of_financial_year(DateTime.now)
      currentFinancialYear = financial_year

      # if range is 6 or less just show it
      if (type=="C") then
        range = if finYearWiseBudgets.size < 7 then
                 finYearWiseBudgets
                # if the last item in the list is less than or equal to 
                # the current financial year get the last 6
                elsif finYearWiseBudgets.last['fy'] <= currentFinancialYear
                  finYearWiseBudgets.last(6)
                # other wise show current FY - 3 years and cuurent FY + 3 years
                else
                  index_of_now = finYearWiseBudgets.index { |i| i['fy'] == currentFinancialYear }

                  if index_of_now.nil? then
                    finYearWiseBudgets.last(6)
                  else
                    finYearWiseBudgets[[index_of_now-3,0].max..index_of_now+2]
                  end
                end
                tempFYear = ""
                tempFYAmount = ""
                finalData = []
                # finally convert the range into a label format
                range.each { |item| 
                  item['fy'] = financial_year_formatter(item['fy'])
                  tempFYear  = tempFYear + "'" + item['fy'] + "'" + ","
                  tempFYAmount = tempFYAmount + "'" + item['value'].to_s + "'" + ","
                }
                finalData[0] = tempFYear
                finalData[1] = tempFYAmount
                return finalData

      elsif (type=="P") then
        finYearWiseBudgets.each { |item| 
          item['fy'] = financial_year_formatter(item['fy']) 
        }
                  	          
      end
  end

  #oipa v2.2
  # def get_actual_budget_per_fy(yearWiseBudgets)      
  #     yearWiseBudgets.to_a.group_by { |b| 
  #         # we want to group them by the first day of 
  #         # the financial year. This allows for calculations
  #         fy =  if  b["quarter"]==1 then
  #                   b["year"]-1
  #               else
  #                   b["year"]
  #               end
  #         #first_day_of_financial_year(date)
  #       }.map { |fy, bs| 
  #           # then we sum up all the values for that financial year
  #           {
  #               "fy"    => fy,
  #               "type"  => "budget",
  #               "value" => bs.inject(0) { |v, b| v + b["value"] },
  #           }
  #       }
  # end

  #oipa v3.1
  def get_actual_budget_per_fy(yearWiseBudgets)      
      yearWiseBudgets.to_a.group_by { |b| 
          # we want to group them by the first day of 
          # the financial year. This allows for calculations
          fy =  if  b["budget_period_start_quarter"]==1 then
                    b["budget_period_start_year"]-1
                else
                    b["budget_period_start_year"]
                end
          #first_day_of_financial_year(date)
        }.map { |fy, bs| 
            # then we sum up all the values for that financial year
            {
                "fy"    => fy,
                "type"  => "budget",
                "value" => bs.inject(0) { |v, b| v + b["value"] },
            }
        }
  end

  def get_spend_budget_per_fy(yearWiseBudgets,type)      
      yearWiseBudgets.to_a.group_by { |b| 
          # we want to group them by the first day of 
          # the financial year. This allows for calculations
          fy =  if  b["transaction_date_quarter"]==1 then
                    b["transaction_date_year"]-1
                else
                    b["transaction_date_year"]
                end
          #first_day_of_financial_year(date)
        }.map { |fy, bs| 
            # then we sum up all the values for that financial year
            {
                "fy"    => fy,
                "value" => bs.inject(0) { |v, b| v + b[type] },
            }
        }
  end

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

  def plannedStartDate(dates)
      begin
        dates.find do |s|
          s["type"]["code"].to_s == "1"
        end["iso_date"]
      rescue
        nil
      end
  end

  def actualStartDate(dates)
      begin
        dates.find do |s|
          s["type"]["code"].to_s == "2"
        end["iso_date"]
      rescue
        nil
      end
    end

    def plannedEndDate(dates)
      begin
        dates.find do |s|
          s["type"]["code"].to_s == "3"
        end["iso_date"]
      rescue
        nil
    end   
  end

  def actualEndDate(dates)
      begin
        dates.find do |s|
          s["type"]["code"].to_s == "4"
        end["iso_date"]
      rescue
        nil
      end
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

  def convert_numbers_to_human_readable_format(num)
    begin
      ActionView::Base.new.number_to_human(num.gsub(",",""), :format => '%n%u', :precision => 3, :units => { :thousand => 'K', :million => 'M', :billion => 'B' })
    rescue
      ActionView::Base.new.number_to_human(num, :format => '%n%u', :precision => 3, :units => { :thousand => 'K', :million => 'M', :billion => 'B' })
    end
  end

  def convert_transactions_for_csv(proj_id,transaction_type)
    if transaction_type == '0'
      get_project_yearwise_budget(proj_id)
    else
      get_transaction_details(proj_id,transaction_type)
    end
  end

  def generate_api_list(listType,listParams,activityStatus)
    apiList = Array.new
    if(listType == 'C')
      # Total project list API call
      apiList.push("activities/?hierarchy=1&format=json&reporting_organisation=#{settings.goverment_department_ids}&page_size=10&fields=descriptions,activity_status,iati_identifier,url,title,reporting_organisations,activity_plus_child_aggregation,aggregations&activity_status=#{activityStatus}&ordering=-activity_plus_child_budget_value&recipient_country=#{listParams}")
      # Sector values JSON API call
      apiList.push("activities/aggregations/?format=json&group_by=sector&aggregations=count&reporting_organisation=#{settings.goverment_department_ids}&recipient_country=#{listParams}&activity_status=#{activityStatus}")
      # Actual Start Date API call
      apiList.push("activities?format=json&page_size=1&fields=activity_dates&reporting_organisation=#{settings.goverment_department_ids}&hierarchy=1&recipient_country=#{listParams}&ordering=actual_start_date&start_date_gte=1900-01-02&activity_status=#{activityStatus}")
      # Planned End Date API call
      apiList.push("activities?format=json&page_size=1&fields=activity_dates&reporting_organisation=#{settings.goverment_department_ids}&hierarchy=1&recipient_country=#{listParams}&ordering=-planned_end_date&end_date_isnull=False&activity_status=#{activityStatus}")
      # Document List API call
      apiList.push("activities/aggregations/?format=json&group_by=document_link_category&aggregations=count&reporting_organisation=#{settings.goverment_department_ids}&recipient_country=#{listParams}&activity_status=#{activityStatus}")
      # Implementing Org List API call
      apiList.push("activities/aggregations/?format=json&group_by=participating_organisation&aggregations=count&reporting_organisation=#{settings.goverment_department_ids}&recipient_country=#{listParams}&hierarchy=1&activity_status=#{activityStatus}")
    elsif (listType == 'R')
      # Total project list API call
      apiList.push("activities/?hierarchy=1&format=json&reporting_organisation=#{settings.goverment_department_ids}&page_size=10&fields=aggregations,descriptions,activity_status,iati_identifier,url,title,reporting_organisations,activity_plus_child_aggregation&activity_status=#{activityStatus}&ordering=-activity_plus_child_budget_value&related_activity_recipient_region=#{listParams}")
      # Sector values JSON API call
      apiList.push("activities/aggregations/?format=json&group_by=sector&aggregations=count&reporting_organisation=#{settings.goverment_department_ids}&related_activity_recipient_region=#{listParams}&activity_status=#{activityStatus}")
      # Actual Start Date API call
      apiList.push("activities/?format=json&page_size=1&fields=activity_dates&reporting_organisation=#{settings.goverment_department_ids}&hierarchy=1&related_activity_recipient_region=#{listParams}&ordering=actual_start_date&start_date_gte=1900-01-02&activity_status=#{activityStatus}")
      # Planned End Date API call
      apiList.push("activities/?format=json&page_size=1&fields=activity_dates&reporting_organisation=#{settings.goverment_department_ids}&hierarchy=1&related_activity_recipient_region=#{listParams}&ordering=-planned_end_date&end_date_isnull=False&activity_status=#{activityStatus}")
      # Document List API call
      apiList.push("activities/aggregations/?format=json&group_by=document_link_category&aggregations=count&reporting_organisation=#{settings.goverment_department_ids}&related_activity_recipient_region=#{listParams}&activity_status=#{activityStatus}")
      # Implementing Org List API call
      apiList.push("activities/aggregations/?format=json&group_by=participating_organisation&aggregations=count&reporting_organisation=#{settings.goverment_department_ids}&related_activity_recipient_region=#{listParams}&hierarchy=1&activity_status=#{activityStatus}")
    elsif (listType == 'S')
      # Total project list API call
      apiList.push("activities/?hierarchy=1&format=json&reporting_organisation=#{settings.goverment_department_ids}&page_size=10&fields=descriptions,activity_status,iati_identifier,url,title,reporting_organisations,activity_plus_child_aggregation,aggregations&activity_status=#{activityStatus}&ordering=-activity_plus_child_budget_value&related_activity_sector=#{listParams}")
      # Sector values JSON API call
      apiList.push("activities/aggregations/?format=json&group_by=sector&aggregations=count&reporting_organisation=#{settings.goverment_department_ids}&related_activity_sector=#{listParams}&activity_status=#{activityStatus}")
      # Actual Start Date API call
      apiList.push("activities/?format=json&page_size=1&fields=activity_dates&reporting_organisation=#{settings.goverment_department_ids}&hierarchy=1&related_activity_sector=#{listParams}&ordering=actual_start_date&start_date_gte=1900-01-02&activity_status=#{activityStatus}")
      # Planned End Date API call
      apiList.push("activities/?format=json&page_size=1&fields=activity_dates&reporting_organisation=#{settings.goverment_department_ids}&hierarchy=1&related_activity_sector=#{listParams}&ordering=-planned_end_date&end_date_isnull=False&activity_status=#{activityStatus}")
      # Document List API call
      apiList.push("activities/aggregations/?format=json&group_by=document_link_category&aggregations=count&reporting_organisation=#{settings.goverment_department_ids}&related_activity_sector=#{listParams}&activity_status=#{activityStatus}")
      # Implementing Org List API call
      apiList.push("activities/aggregations/?format=json&group_by=participating_organisation&aggregations=count&reporting_organisation=#{settings.goverment_department_ids}&hierarchy=1&related_activity_sector=#{listParams}&activity_status=#{activityStatus}")
    elsif (listType == 'F')
      # Total project list API call
      #apiList.push("activities/?hierarchy=1&format=json&page_size=10&fields=aggregations,descriptions,activity_status,iati_identifier,url,title,reporting_organisations,activity_plus_child_aggregation&q=#{listParams}&activity_status=#{activityStatus}&ordering=-activity_plus_child_budget_value&reporting_organisation_startswith=GB")
      apiList.push("activities/?hierarchy=1&format=json&page_size=10&fields=aggregations,descriptions,activity_status,iati_identifier,url,title,reporting_organisations,activity_plus_child_aggregation&q=#{listParams}&activity_status=#{activityStatus}&ordering=-activity_plus_child_budget_value")
      # Sector values JSON API call
      apiList.push("activities/aggregations/?format=json&group_by=sector&aggregations=count&q=#{listParams}&activity_status=#{activityStatus}")
      # Actual Start Date API call
      apiList.push("activities/?format=json&page_size=1&fields=activity_dates&hierarchy=1&q=#{listParams}&ordering=actual_start_date&start_date_gte=1900-01-02&activity_status=#{activityStatus}")
      # Planned End Date API call
      apiList.push("activities/?format=json&page_size=1&fields=activity_dates&hierarchy=1&q=#{listParams}&ordering=-planned_end_date&end_date_isnull=False&activity_status=#{activityStatus}")
      # Document List API call
      apiList.push("activities/aggregations/?format=json&group_by=document_link_category&aggregations=count&q=#{listParams}&activity_status=#{activityStatus}")
      # Implementing Org List API call
      apiList.push("activities/aggregations/?format=json&group_by=participating_organisation&aggregations=count&q=#{listParams}&hierarchy=1&activity_status=#{activityStatus}")
    elsif (listType == 'O')
      # Total project list API call
      apiList.push("activities/?hierarchy=1&format=json&reporting_organisation=#{listParams}&page_size=10&fields=descriptions,activity_status,iati_identifier,url,title,reporting_organisations,activity_plus_child_aggregation,aggregations&activity_status=#{activityStatus}&ordering=-activity_plus_child_budget_value")
      # Sector values JSON API call
      apiList.push("activities/aggregations/?format=json&group_by=sector&aggregations=count&reporting_organisation=#{listParams}&activity_status=#{activityStatus}")
      # Actual Start Date API call
      apiList.push("activities?format=json&page_size=1&fields=activity_dates&reporting_organisation=#{listParams}&hierarchy=1&ordering=actual_start_date&start_date_gte=1900-01-02&activity_status=#{activityStatus}")
      # Planned End Date API call
      apiList.push("activities?format=json&page_size=1&fields=activity_dates&reporting_organisation=#{listParams}&hierarchy=1&ordering=-planned_end_date&end_date_isnull=False&activity_status=#{activityStatus}")
      # Document List API call
      apiList.push("activities/aggregations/?format=json&group_by=document_link_category&aggregations=count&reporting_organisation=#{listParams}&activity_status=#{activityStatus}")
      # Implementing Org List API call
      apiList.push("activities/aggregations/?format=json&group_by=participating_organisation&aggregations=count&reporting_organisation=#{listParams}&hierarchy=1&activity_status=#{activityStatus}")
    end
  end

  def generate_project_page_data(apiList)
    allProjectsData = {}
    puts apiList[0]
    oipa_project_list = RestClient.get settings.oipa_api_url + apiList[0]
    allProjectsData['projects']= JSON.parse(oipa_project_list)
    sectorValuesJSON = RestClient.get settings.oipa_api_url + apiList[1]
    allProjectsData['highLevelSectorList'] = high_level_sector_list_filter(sectorValuesJSON)
    allProjectsData['project_budget_higher_bound'] = 0
    allProjectsData['actualStartDate'] = '1990-01-01T00:00:00' 
    allProjectsData['plannedEndDate'] = '2000-01-01T00:00:00'
    unless allProjectsData['projects']['results'][0].nil?
      allProjectsData['project_budget_higher_bound'] = allProjectsData['projects']['results'][0]['aggregations']['activity_children']['budget_value']
    end
    begin
      allProjectsData['actualStartDate'] = RestClient.get settings.oipa_api_url + apiList[2]
      allProjectsData['actualStartDate'] = JSON.parse(allProjectsData['actualStartDate'])
      tempStartDate = allProjectsData['actualStartDate']['results'][0]['activity_dates'].select{|activityDate| activityDate['type']['code'] == '2'}.first
      if (tempStartDate.nil?)
        tempStartDate = allProjectsData['actualStartDate']['results'][0]['activity_dates'].select{|activityDate| activityDate['type']['code'] == '1'}.first
      end
      allProjectsData['actualStartDate'] = tempStartDate
      allProjectsData['actualStartDate'] = allProjectsData['actualStartDate']['iso_date']
    rescue
      allProjectsData['actualStartDate'] = '1990-01-01T00:00:00'
    end

    #unless allProjectsData['actualStartDate']['results'][0].nil? 
    #  allProjectsData['actualStartDate'] = allProjectsData['actualStartDate']['results'][0]['activity_dates'][1]['iso_date']
    #end
    begin
      allProjectsData['plannedEndDate'] = RestClient.get settings.oipa_api_url + apiList[3]
      allProjectsData['plannedEndDate'] = JSON.parse(allProjectsData['plannedEndDate'])
      allProjectsData['plannedEndDate'] = allProjectsData['plannedEndDate']['results'][0]['activity_dates'].select{|activityDate| activityDate['type']['code'] == '3' || activityDate['type']['code'] == '4'}.first
      allProjectsData['plannedEndDate'] = allProjectsData['plannedEndDate']['iso_date']
    rescue
      #allProjectsData['plannedEndDate'] = '2000-01-01T00:00:00'
      allProjectsData['plannedEndDate'] = Date.today
    end
    #unless allProjectsData['plannedEndDate']['results'][0].nil?
    #  allProjectsData['plannedEndDate'] = allProjectsData['plannedEndDate']['results'][0]['activity_dates'][2]['iso_date']
    #end
    oipa_document_type_list = RestClient.get settings.oipa_api_url + apiList[4]
    document_type_list = JSON.parse(oipa_document_type_list)
    allProjectsData['document_types'] = document_type_list['results']

    #Implementing org type filters
    participatingOrgInfo = JSON.parse(File.read('data/participatingOrgList.json'))
    oipa_implementingOrg_type_list = RestClient.get settings.oipa_api_url + apiList[5]
    implementingOrg_type_list = JSON.parse(oipa_implementingOrg_type_list)
    allProjectsData['implementingOrg_types'] = implementingOrg_type_list['results']
    allProjectsData['implementingOrg_types'].each do |implementingOrgs|
      if implementingOrgs['participating_organisation'].length < 1
        tempImplmentingOrgData = participatingOrgInfo.select{|implementingOrg| implementingOrg['Code'].to_s == implementingOrgs['participating_organisation_ref'].to_s}.first
        if tempImplmentingOrgData.nil?
          implementingOrgs['participating_organisation_ref'] = 'na'
          implementingOrgs['participating_organisation'] = 'na'
        else
          implementingOrgs['participating_organisation'] = tempImplmentingOrgData['Name']
        end
      end
    end
    allProjectsData['highLevelSectorList'] = allProjectsData['highLevelSectorList'].sort_by {|key| key}
    allProjectsData['document_types'] = allProjectsData['document_types'].sort_by {|key| key["document_link_category"]["name"]}
    allProjectsData['implementingOrg_types'] = allProjectsData['implementingOrg_types'].sort_by {|key| key["participating_organisation"]}.uniq {|key| key["participating_organisation_ref"]}
    return allProjectsData
  end

  #######################################
  ## Methods for returning LHS filters ##
  #######################################

  #Return projects and budget higher bound information
  def generateProjectListWithBudgetHiBound(apiLink)
    allProjectsData = {}
    oipa_project_list = RestClient.get settings.oipa_api_url + apiLink
    allProjectsData['projects']= JSON.parse(oipa_project_list)
    allProjectsData['project_budget_higher_bound'] = 0
    unless allProjectsData['projects']['results'][0].nil?
      allProjectsData['project_budget_higher_bound'] = allProjectsData['projects']['results'][0]['aggregations']['activity_children']['budget_value']
    end
    allProjectsData
  end

  #Return budget higher bound information
  def generateBudgetHiBound(apiLink)
    oipa_project_list = RestClient.get settings.oipa_api_url + apiLink
    oipa_project_list = JSON.parse(oipa_project_list)
    project_budget_higher_bound = 0
    unless oipa_project_list['results'][0].nil?
      project_budget_higher_bound = oipa_project_list['results'][0]['aggregations']['activity_children']['budget_value']
    end
    project_budget_higher_bound
  end

  #Return High Level sector List
  def generateSectorList(apiLink)
    sectorValuesJSON = RestClient.get settings.oipa_api_url + apiLink
    highLevelSectorList = high_level_sector_list_filter(sectorValuesJSON)
    highLevelSectorList = highLevelSectorList.sort_by {|key| key}
    highLevelSectorList
  end

  #Returns project start date
  def generateProjectStartDate(apiLink)
    startDate = '1990-01-01T00:00:00'
    begin
      puts apiLink
      tempStartDate = RestClient.get settings.oipa_api_url + apiLink
      tempStartDate = JSON.parse(tempStartDate)
      tempStartDate = tempStartDate['results'][0]['activity_dates'].select{|activityDate| activityDate['type']['code'] == '2'}.first
      if (tempStartDate.nil?)
        tempStartDate = tempStartDate['results'][0]['activity_dates'].select{|activityDate| activityDate['type']['code'] == '1'}.first
      end
      startDate = tempStartDate['iso_date']
    rescue
      startDate = '1990-01-01T00:00:00'
    end
    startDate
  end
  
  #Returns project end date
  def generateProjectEndDate(apiLink)
    endDate = '2000-01-01T00:00:00'
    begin
      tempEndDate = RestClient.get settings.oipa_api_url + apiLink
      tempEndDate = JSON.parse(tempEndDate)
      tempEndDate = tempEndDate['results'][0]['activity_dates'].select{|activityDate| activityDate['type']['code'] == '3' || activityDate['type']['code'] == '4'}.first
      endDate = tempEndDate['iso_date']
    rescue
      endDate = Date.today
    end
    endDate
  end
  
  #Return Document Type List
  def generateDocumentTypeList(apiLink)
    oipa_document_type_list = RestClient.get settings.oipa_api_url + apiLink
    document_type_list = JSON.parse(oipa_document_type_list)
    document_type_list = document_type_list['results']
    document_type_list = document_type_list.sort_by {|key| key["document_link_category"]["name"]}
    document_type_list
  end

  #Return Implementing Org List
  def generateImplOrgList(apiLink)
    participatingOrgInfo = JSON.parse(File.read('data/participatingOrgList.json'))
    oipa_implementingOrg_type_list = RestClient.get settings.oipa_api_url + apiLink
    implementingOrg_type_list = JSON.parse(oipa_implementingOrg_type_list)
    implementingOrg_type_list = implementingOrg_type_list['results']
    implementingOrg_type_list.each do |implementingOrgs|
      if implementingOrgs['participating_organisation'].length < 1
        tempImplmentingOrgData = participatingOrgInfo.select{|implementingOrg| implementingOrg['Code'].to_s == implementingOrgs['participating_organisation_ref'].to_s}.first
        if tempImplmentingOrgData.nil?
          implementingOrgs['participating_organisation_ref'] = 'na'
          implementingOrgs['participating_organisation'] = 'na'
        else
          implementingOrgs['participating_organisation'] = tempImplmentingOrgData['Name']
        end
      end
    end
    implementingOrg_type_list = implementingOrg_type_list.sort_by {|key| key["participating_organisation"]}.uniq {|key| key["participating_organisation_ref"]}
  end
end
