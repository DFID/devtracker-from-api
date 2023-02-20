require "active_support/all"

include ActionView::Helpers::NumberHelper

module CommonHelpers

  def api_simple_log(apiLink)
    if(settings.log_api_calls)
      open('data/apiTelem/api_out.tsv', 'a') do |f|
        # get stacktrace and filter for devtracker code
        time = String(Time.now.iso8601)
        route = request.env['sinatra.route']
        stackstring = "[" + caller.map {|x| x =~ /devtracker/i ? x : nil}.reject!(&:nil?).join(",") + "]"
        f.puts time + "\t" + route + "\t'" + apiLink + "'\t'" + stackstring + "'\n"
        #f.puts time + "\t" + route + "\t'" + apiLink + "'\n"
      end
    end
    return apiLink
  end

  def get_total_spend()
    count = 20
    apiCall = settings.oipa_api_url_other +  "activity/?q=reporting_org_ref:GB-GOV-* AND hierarchy:2&start=0&rows=#{count}&fl=transaction_type,transaction_value,activity_status_code"
    apiCall = JSON.parse(RestClient.get apiCall)
    page = 1
    page = page.to_i - 1
    finalPage = page * count
    numOActivities = apiCall['response']['numFound'].to_i
    pulledData = apiCall['response']['docs']
    if numOActivities > count
      pages = (numOActivities.to_f/count).ceil
      for p in 2..pages do
        p = p - 1
        finalPage = p * count
        tempData = JSON.parse(RestClient.get settings.oipa_api_url_other + "activity/?q=reporting_org_ref:GB-GOV-* AND hierarchy:2&start=#{finalPage}&rows=#{count}&fl=transaction_type,transaction_value,activity_status_code")
        tempData = tempData['response']['docs']
        tempData.each do |item|
          pulledData.push(item)
        end
      end
    end
    totalSpend = 0
    pulledData.each do |item|
      if item.has_key?('transaction_type')
        item['transaction_type'].each_with_index do |i, index|
          if i.to_i == 3 || i.to_i == 4 || i.to_i == 8
            totalSpend = totalSpend + item['transaction_value'][index].to_f
          end
        end
      end
    end
    #Money.new(totalSpend.to_f.round(0)*100, 'GBP').format(:no_cents_if_whole => true,:sign_before_symbol => false)
    totalSpend
  end

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
      puts finYearWiseBudgets
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
      elsif (type=='C2') then
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
                finalData = {}
                # finally convert the range into a label format
                range.each { |item| 
                  item['fy'] = financial_year_formatter(item['fy'])
                  finalData[item['fy']] = item['value']
                }
                return finalData
      elsif (type=="P") then
        finYearWiseBudgets.each { |item| 
          item['fy'] = financial_year_formatterv2(item['fy']) 
        }
                  	          
      end
  end

  def financial_year_wise_budgetsv2(yearWiseBudgets,type)

    finYearWiseBudgets = get_actual_budget_per_fyv2(yearWiseBudgets)
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
    elsif (type=='C2') then
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
              finalData = {}
              # finally convert the range into a label format
              range.each { |item| 
                item['fy'] = financial_year_formatter(item['fy'])
                finalData[item['fy']] = item['value']
              }
              return finalData
    elsif (type=="P") then
      finYearWiseBudgets.each { |item| 
        item['fy'] = financial_year_formatterv2(item['fy']) 
      }  
    end
end

def get_actual_budget_per_fyv2(yearWiseBudgets)
  hash = {}
  yearWiseBudgets.each do |project|
    if project.has_key?('budget_period_start_iso_date')
      project['budget_period_start_iso_date'].each_with_index do |data, index|
        t = Time.parse(data)
        fy = if project['budget.period-start.quarter'][index].to_i == 1 then t.year - 1 else t.year end
        #quarter = if project['budget.period-start.quarter'][index].to_i == 1 then 4 else project['budget.period-start.quarter'][index].to_i - 1 end
        if hash.has_key?(fy)
          hash[fy] = hash[fy] + project['budget_value'][index]
        else
          hash[fy] = project['budget_value'][index]
        end
      end
    end
  end
  finalData = []
  #hash.each do |key, val|
  hash.sort.map do |key, val|
    tempData = {}
    tempData['fy'] = key
    tempData['type'] = 'budget'
    tempData['value'] = val
    finalData.push(tempData)
  end
  finalData
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

  def get_actual_budget_per_dept_per_fy(yearWiseDeptBudgets)      
      yearWiseDeptBudgets.to_a.group_by { |b| 
          # we want to group them by the first day of 
          # the financial year. This allows for calculations
          [if  b["budget_period_start_quarter"]==1 then
                    b["budget_period_start_year"]-1
                else
                    b["budget_period_start_year"]
                end,
                b["reporting_organisation"]["primary_name"]]
          #first_day_of_financial_year(date)
        }.map { |fy, bs| 
            # then we sum up all the values for that financial year
            {
                "fy"    => fy[0],
                "dept"  => fy[1],
                "value" => bs.inject(0) { |v, b| v + b["value"] },
            }
        }.sort_by{ |k| k["fy"]}
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

  def get_financial_year(d) 
    d = Time.parse(d)
    if(d.month < 4)
      d.year-1
    else
      d.year
    end
  end

  def format_datev2(d)
    begin
      d = Time.parse(d)
      str = d.year.to_s + '-' + d.month.to_s + '-' + d.day.to_s
      str
    rescue
      print(d)
    end
  end

  def plannedStartDate(dates)
    finalData = nil
    begin
      dates['activity_date_type'].each_with_index do |d, index|
        if(d.to_s == '1')
          finalData = dates['activity_date_iso_date'][index]
        end
      end
      # dates['activity_date_type'].find do |s|
      #   s.to_s == "1"
      # end["iso_date"]
    rescue
      finalData = nil
    end
    finalData
  end

  def actualStartDate(dates)
    finalData = nil
    begin
      dates['activity_date_type'].each_with_index do |d, index|
        if(d.to_s == '2')
          finalData = dates['activity_date_iso_date'][index]
        end
      end
      # dates.find do |s|
      #   s["type"]["code"].to_s == "2"
      # end["iso_date"]
    rescue
      finalData = nil
    end
    finalData
  end

  def plannedEndDate(dates)
    finalData = nil
    begin
      dates['activity_date_type'].each_with_index do |d, index|
        if(d.to_s == '3')
          finalData = dates['activity_date_iso_date'][index]
        end
      end
      rescue
        finalData = nil
    end
    finalData 
  end

  def actualEndDate(dates)
    finalData = nil
    begin
      dates['activity_date_type'].each_with_index do |d, index|
        if(d.to_s == '4')
          finalData = dates['activity_date_iso_date'][index]
        end
      end
    rescue
      finalData = nil
    end
    finalData
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
      number_to_human(num.gsub(",",""), :format => '%n%u', :precision => 3, :units => { :thousand => 'K', :million => 'M', :billion => 'B' })
    rescue
      number_to_human(num, :format => '%n%u', :precision => 3, :units => { :thousand => 'K', :million => 'M', :billion => 'B' })
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
      apiList.push("activities/?hierarchy=1&format=json&reporting_organisation_identifier=#{settings.goverment_department_ids}&page_size=20&fields=activity_dates,descriptions,activity_status,iati_identifier,url,title,reporting_organisation,activity_plus_child_aggregation,aggregations&activity_status=#{activityStatus}&ordering=-activity_plus_child_budget_value&recipient_country=#{listParams}")
      # Sector values JSON API call
      apiList.push("activities/aggregations/?format=json&group_by=sector&aggregations=count&reporting_organisation_identifier=#{settings.goverment_department_ids}&recipient_country=#{listParams}&activity_status=#{activityStatus}")
      # Actual Start Date API call
      apiList.push("activities?format=json&page_size=1&fields=activity_dates&reporting_organisation_identifier=#{settings.goverment_department_ids}&hierarchy=1&recipient_country=#{listParams}&ordering=actual_start_date&start_date_gte=1900-01-02&activity_status=#{activityStatus}")
      # Planned End Date API call
      apiList.push("activities?format=json&page_size=1&fields=activity_dates&reporting_organisation_identifier=#{settings.goverment_department_ids}&hierarchy=1&recipient_country=#{listParams}&ordering=-planned_end_date&end_date_isnull=False&activity_status=#{activityStatus}")
      # Document List API call
      apiList.push("activities/aggregations/?format=json&group_by=document_link_category&aggregations=count&reporting_organisation_identifier=#{settings.goverment_department_ids}&recipient_country=#{listParams}&activity_status=#{activityStatus}")
      # Implementing Org List API call
      apiList.push("activities/aggregations/?format=json&group_by=participating_organisation&aggregations=count&reporting_organisation_identifier=#{settings.goverment_department_ids}&recipient_country=#{listParams}&hierarchy=1&activity_status=#{activityStatus}")
      # This is to return data sorted according to actual start date
      apiList.push("activities/?hierarchy=1&format=json&reporting_organisation_identifier=#{settings.goverment_department_ids}&page_size=20&fields=activity_dates,descriptions,activity_status,iati_identifier,url,title,reporting_organisation,activity_plus_child_aggregation,aggregations&activity_status=#{activityStatus}&ordering=actual_start_date&recipient_country=#{listParams}")
      # Reporting Org List API call
      apiList.push("activities/aggregations/?format=json&group_by=reporting_organisation&aggregations=count&reporting_organisation_identifier=#{settings.goverment_department_ids}&recipient_country=#{listParams}&hierarchy=1&activity_status=#{activityStatus}")
    elsif (listType == 'R')
      # Total project list API call
      apiList.push("activities/?hierarchy=1&format=json&reporting_organisation_identifier=#{settings.goverment_department_ids}&page_size=20&fields=activity_dates,aggregations,descriptions,activity_status,iati_identifier,url,title,reporting_organisation,activity_plus_child_aggregation&activity_status=#{activityStatus}&ordering=-activity_plus_child_budget_value&recipient_region=#{listParams}")
      # Sector values JSON API call
      apiList.push("activities/aggregations/?format=json&group_by=sector&aggregations=count&reporting_organisation_identifier=#{settings.goverment_department_ids}&recipient_region=#{listParams}&activity_status=#{activityStatus}")
      # Actual Start Date API call
      apiList.push("activities/?format=json&page_size=1&fields=activity_dates&reporting_organisation_identifier=#{settings.goverment_department_ids}&hierarchy=1&recipient_region=#{listParams}&ordering=actual_start_date&start_date_gte=1900-01-02&activity_status=#{activityStatus}")
      # Planned End Date API call
      apiList.push("activities/?format=json&page_size=1&fields=activity_dates&reporting_organisation_identifier=#{settings.goverment_department_ids}&hierarchy=1&recipient_region=#{listParams}&ordering=-planned_end_date&end_date_isnull=False&activity_status=#{activityStatus}")
      # Document List API call
      apiList.push("activities/aggregations/?format=json&group_by=document_link_category&aggregations=count&reporting_organisation_identifier=#{settings.goverment_department_ids}&recipient_region=#{listParams}&activity_status=#{activityStatus}")
      # Implementing Org List API call
      apiList.push("activities/aggregations/?format=json&group_by=participating_organisation&aggregations=count&reporting_organisation_identifier=#{settings.goverment_department_ids}&recipient_region=#{listParams}&hierarchy=1&activity_status=#{activityStatus}")
      # Reporting Org List API call
      apiList.push("activities/aggregations/?format=json&group_by=reporting_organisation&aggregations=count&reporting_organisation_identifier=#{settings.goverment_department_ids}&recipient_region=#{listParams}&hierarchy=1&activity_status=#{activityStatus}")
    elsif (listType == 'S')
      # Total project list API call
      apiList.push("activities/?hierarchy=1&format=json&reporting_organisation_identifier=#{settings.goverment_department_ids}&page_size=20&fields=activity_dates,descriptions,activity_status,iati_identifier,url,title,reporting_organisation,activity_plus_child_aggregation,aggregations&activity_status=#{activityStatus}&ordering=-activity_plus_child_budget_value&related_activity_sector=#{listParams}")
      # Sector values JSON API call
      apiList.push("activities/aggregations/?format=json&group_by=sector&aggregations=count&reporting_organisation_identifier=#{settings.goverment_department_ids}&related_activity_sector=#{listParams}&activity_status=#{activityStatus}")
      # Actual Start Date API call
      apiList.push("activities/?format=json&page_size=1&fields=activity_dates&reporting_organisation_identifier=#{settings.goverment_department_ids}&hierarchy=1&related_activity_sector=#{listParams}&ordering=actual_start_date&start_date_gte=1900-01-02&activity_status=#{activityStatus}")
      # Planned End Date API call
      apiList.push("activities/?format=json&page_size=1&fields=activity_dates&reporting_organisation_identifier=#{settings.goverment_department_ids}&hierarchy=1&related_activity_sector=#{listParams}&ordering=-planned_end_date&end_date_isnull=False&activity_status=#{activityStatus}")
      # Document List API call
      apiList.push("activities/aggregations/?format=json&group_by=document_link_category&aggregations=count&reporting_organisation_identifier=#{settings.goverment_department_ids}&related_activity_sector=#{listParams}&activity_status=#{activityStatus}")
      # Implementing Org List API call
      apiList.push("activities/aggregations/?format=json&group_by=participating_organisation&aggregations=count&reporting_organisation_identifier=#{settings.goverment_department_ids}&hierarchy=1&related_activity_sector=#{listParams}&activity_status=#{activityStatus}")
      # Reporting Org List API call
      apiList.push("activities/aggregations/?format=json&group_by=reporting_organisation&aggregations=count&reporting_organisation_identifier=#{settings.goverment_department_ids}&hierarchy=1&related_activity_sector=#{listParams}&activity_status=#{activityStatus}")
    elsif (listType == 'F')
      # Total project list API call
      #apiList.push("activities/?hierarchy=1&format=json&page_size=10&fields=aggregations,descriptions,activity_status,iati_identifier,url,title,reporting_organisations,activity_plus_child_aggregation&q=#{listParams}&activity_status=#{activityStatus}&ordering=-activity_plus_child_budget_value&reporting_organisation_startswith=GB")
      apiList.push("activities/?hierarchy=1&format=json&page_size=20&fields=activity_dates,aggregations,descriptions,activity_status,iati_identifier,url,title,reporting_organisation,activity_plus_child_aggregation&q=#{listParams}&activity_status=#{activityStatus}&ordering=-activity_plus_child_budget_value")
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
      # Reporting Org List API call
      apiList.push("activities/aggregations/?format=json&group_by=reporting_organisation&aggregations=count&q=#{listParams}&hierarchy=1&activity_status=#{activityStatus}&reporting_organisation_identifier=#{settings.goverment_department_ids}")
    elsif (listType == 'O')
      # Total project list API call
      apiList.push("activities/?hierarchy=1&format=json&reporting_organisation_identifier=#{listParams}&page_size=20&fields=activity_dates,descriptions,activity_status,iati_identifier,url,title,reporting_organisation,activity_plus_child_aggregation,aggregations&activity_status=#{activityStatus}&ordering=-activity_plus_child_budget_value")
      # Sector values JSON API call
      apiList.push("activities/aggregations/?format=json&group_by=sector&aggregations=count&reporting_organisation_identifier=#{listParams}&activity_status=#{activityStatus}")
      # Actual Start Date API call
      apiList.push("activities?format=json&page_size=1&fields=activity_dates&reporting_organisation_identifier=#{listParams}&hierarchy=1&ordering=actual_start_date&start_date_gte=1900-01-02&activity_status=#{activityStatus}")
      # Planned End Date API call
      apiList.push("activities?format=json&page_size=1&fields=activity_dates&reporting_organisation_identifier=#{listParams}&hierarchy=1&ordering=-planned_end_date&end_date_isnull=False&activity_status=#{activityStatus}")
      # Document List API call
      apiList.push("activities/aggregations/?format=json&group_by=document_link_category&aggregations=count&reporting_organisation_identifier=#{listParams}&activity_status=#{activityStatus}")
      # Implementing Org List API call
      apiList.push("activities/aggregations/?format=json&group_by=participating_organisation&aggregations=count&reporting_organisation_identifier=#{listParams}&hierarchy=1&activity_status=#{activityStatus}")
      # Reporting Org List API call
      apiList.push("activities/aggregations/?format=json&group_by=reporting_organisation&aggregations=count&reporting_organisation_identifier=#{listParams}&hierarchy=1&activity_status=#{activityStatus}")
    end
  end

  def generate_project_page_data(apiList)
    allProjectsData = {}
    oipa_project_list = RestClient.get  api_simple_log(settings.oipa_api_url + apiList[0])
    allProjectsData['projects']= JSON.parse(oipa_project_list)

    allProjectsData['projects']['results'] = allProjectsData['projects']['results'].select{|a| a['recipient_countries'].select{|b| b['country']['code'].to_s == 'UA'}.length() == 0}
    allProjectsData['projects']['count'] = allProjectsData['projects']['results'].length()

    sectorValuesJSON = RestClient.get  api_simple_log(settings.oipa_api_url + apiList[1])
    allProjectsData['highLevelSectorList'] = high_level_sector_list_filter(sectorValuesJSON)
    allProjectsData['project_budget_higher_bound'] = 0
    allProjectsData['actualStartDate'] = '1990-01-01T00:00:00' 
    allProjectsData['plannedEndDate'] = '2000-01-01T00:00:00'
    unless allProjectsData['projects']['results'][0].nil?
      allProjectsData['project_budget_higher_bound'] = allProjectsData['projects']['results'][0]['activity_plus_child_aggregation']['activity_children']['budget_value']
    end
    # This part is for sorting the returned data based on actual start date. For now, this is applicable for country projects page only.
    if (apiList[0].include? "recipient_country")
      oipa_project_list = RestClient.get  api_simple_log(settings.oipa_api_url + apiList[6])
      allProjectsData['projects']= JSON.parse(oipa_project_list)

      allProjectsData['projects']['results'] = allProjectsData['projects']['results'].select{|a| a['recipient_countries'].select{|b| b['country']['code'].to_s == 'UA'}.length() == 0}
      allProjectsData['projects']['count'] = allProjectsData['projects']['results'].length()
    end
    begin
      allProjectsData['actualStartDate'] = RestClient.get  api_simple_log(settings.oipa_api_url + apiList[2])
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
      allProjectsData['plannedEndDate'] = RestClient.get  api_simple_log(settings.oipa_api_url + apiList[3])
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
    oipa_document_type_list = RestClient.get  api_simple_log(settings.oipa_api_url + apiList[4])
    document_type_list = JSON.parse(oipa_document_type_list)
    allProjectsData['document_types'] = document_type_list['results']

    #Implementing org type filters
    #participatingOrgInfo = JSON.parse(File.read('data/participatingOrgList.json'))
    # Get the list of valid iati publisher identifiers
    iatiPublisherList = JSON.parse(File.read('data/iati_publishers_list.json'))
    oipa_implementingOrg_type_list = RestClient.get  api_simple_log(settings.oipa_api_url + apiList[5])
    implementingOrg_type_list = JSON.parse(oipa_implementingOrg_type_list)
    allProjectsData['implementingOrg_types'] = implementingOrg_type_list['results']
    allProjectsData['implementingOrg_types'].each do |implementingOrgs|
      if implementingOrgs['participating_organisation'].length < 1
        #tempImplmentingOrgData = participatingOrgInfo.select{|implementingOrg| implementingOrg['Code'].to_s == implementingOrgs['participating_organisation_ref'].to_s}.first
        tempImplmentingOrgData = iatiPublisherList.select{|implementingOrg| implementingOrg['IATI Organisation Identifier'].to_s == implementingOrgs['participating_organisation_ref'].to_s}.first        
        if tempImplmentingOrgData.nil?
          implementingOrgs['participating_organisation_ref'] = 'na'
          implementingOrgs['participating_organisation'] = 'na'
        else
          implementingOrgs['participating_organisation'] = tempImplmentingOrgData['Publisher']
        end
      elsif implementingOrgs['participating_organisation_ref'].length < 1 || implementingOrgs['participating_organisation_ref'] == 'NULL'
        implementingOrgs['participating_organisation_ref'] = 'na'
        implementingOrgs['participating_organisation'] = 'na'
      else
        tempImplmentingOrgData = iatiPublisherList.select{|implementingOrg| implementingOrg['IATI Organisation Identifier'].to_s == implementingOrgs['participating_organisation_ref'].to_s}.first
        if tempImplmentingOrgData.nil?
          implementingOrgs['participating_organisation_ref'] = 'na'
          implementingOrgs['participating_organisation'] = 'na'
        else
          implementingOrgs['participating_organisation'] = tempImplmentingOrgData['Publisher']
          implementingOrgs['participating_organisation_ref'] = tempImplmentingOrgData['IATI Organisation Identifier']
        end
      end
    end

    # Reporting org type filter preparation
    if (apiList[0].include? "recipient_country")
      reportingOrgList = RestClient.get  api_simple_log(settings.oipa_api_url + apiList[7])
    else
      reportingOrgList = RestClient.get  api_simple_log(settings.oipa_api_url + apiList[6])
    end
    reportingOrgList = JSON.parse(reportingOrgList)
    reportingOrgList = reportingOrgList['results']
    finalReportingOrgList = Array.new
    reportingOrgList.each do |org|
      tempHash = {}
      tempDepartment = returnDepartmentName(org['reporting_organisation']['organisation_identifier'])
      if(tempDepartment != 'N/A')
        isItemExist = checkIfItemExist(finalReportingOrgList,'organisaion_name',tempDepartment)
        if(isItemExist != -1)
          finalReportingOrgList[isItemExist]['organisation_identifier'] = finalReportingOrgList[isItemExist]['organisation_identifier'] + ',' + org['reporting_organisation']['organisation_identifier']
        else
          tempHash['organisation_identifier'] = org['reporting_organisation']['organisation_identifier']
          tempHash['organisaion_name'] = tempDepartment
          finalReportingOrgList.push(tempHash)
        end
      end
    end
    # Dat sorting
    allProjectsData['highLevelSectorList'] = allProjectsData['highLevelSectorList'].sort_by {|key| key}
    allProjectsData['document_types'] = allProjectsData['document_types'].sort_by {|key| key["document_link_category"]["name"]}
    allProjectsData['implementingOrg_types'] = allProjectsData['implementingOrg_types'].sort_by {|key| key["participating_organisation"]}.uniq {|key| key["participating_organisation_ref"]}
    allProjectsData['reportingOrg_types'] = finalReportingOrgList.sort_by{|key| key['organisaion_name']}
    return allProjectsData
  end

  def checkIfItemExist(arr,k,itemToSearch)
    searchedItem = -1
    arr.each_index do |x|
      if(arr[x][k].to_s == itemToSearch.to_s)
        searchedItem = x
        break
      end
    end
    searchedItem
  end

  #######################################
  ## Methods for returning LHS filters ##
  #######################################

  #Return projects and budget higher bound information
  def generateProjectListWithBudgetHiBound(apiLink)
    allProjectsData = {}
    oipa_project_list = RestClient.get  api_simple_log(settings.oipa_api_url + apiLink)
    allProjectsData['projects']= JSON.parse(oipa_project_list)

    allProjectsData['projects']['results'] = allProjectsData['projects']['results'].select{|a| a['recipient_countries'].select{|b| b['country']['code'].to_s == 'UA'}.length() == 0}
    allProjectsData['projects']['count'] = allProjectsData['projects']['results'].length()

    allProjectsData['project_budget_higher_bound'] = 0
    unless allProjectsData['projects']['results'][0].nil?
      allProjectsData['project_budget_higher_bound'] = allProjectsData['projects']['results'][0]['activity_plus_child_aggregation']['activity_children']['budget_value']
    end
    allProjectsData
  end

  #Return budget higher bound information
  def generateBudgetHiBound(apiLink)
    oipa_project_list = RestClient.get  api_simple_log(settings.oipa_api_url + apiLink)
    oipa_project_list = JSON.parse(oipa_project_list)
    project_budget_higher_bound = 0
    unless oipa_project_list['results'][0].nil?
      project_budget_higher_bound = oipa_project_list['results'][0]['activity_plus_child_aggregation']['activity_children']['budget_value']
    end
    project_budget_higher_bound
  end

  #Return High Level sector List
  def generateSectorList(apiLink)
    sectorValuesJSON = RestClient.get  api_simple_log(settings.oipa_api_url + apiLink)
    highLevelSectorList = high_level_sector_list_filter(sectorValuesJSON)
    highLevelSectorList = highLevelSectorList.sort_by {|key| key}
    highLevelSectorList
  end

  #Returns project start date
  def generateProjectStartDate(apiLink)
    startDate = '1990-01-01T00:00:00'
    begin
      tempStartDate = RestClient.get  api_simple_log(settings.oipa_api_url + apiLink)
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
      tempEndDate = RestClient.get  api_simple_log(settings.oipa_api_url + apiLink)
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
    oipa_document_type_list = RestClient.get  api_simple_log(settings.oipa_api_url + apiLink)
    document_type_list = JSON.parse(oipa_document_type_list)
    document_type_list = document_type_list['results']
    document_type_list = document_type_list.sort_by {|key| key["document_link_category"]["name"]}
    document_type_list
  end

  #Return Implementing Org List
  def generateImplOrgList(apiLink)
    participatingOrgInfo = JSON.parse(File.read('data/participatingOrgList.json'))
    oipa_implementingOrg_type_list = RestClient.get  api_simple_log(settings.oipa_api_url + apiLink)
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

  #Return Reporting Org List
  def generateReportingOrgList(apiLink)
    reportingOrgList = RestClient.get  api_simple_log(settings.oipa_api_url + apiLink)
    reportingOrgList = JSON.parse(reportingOrgList)
    reportingOrgList = reportingOrgList['results']
    finalReportingOrgList = Array.new
    reportingOrgList.each do |org|
      tempHash = {}
      tempHash['organisation_identifier'] = org['reporting_organisation']['organisation_identifier']
      tempHash['organisaion_name'] = returnDepartmentName(org['reporting_organisation']['organisation_identifier'])
      finalReportingOrgList.push(tempHash)
    end
    finalList = finalReportingOrgList.sort_by{|key| key['organisaion_name']}
  end  

  #Serve the aid by location country page table data
  def generateCountryDatav2()
    #newApiCall = settings.oipa_api_url_other + "budget?q=reporting_org_ref:(#{settings.goverment_department_ids.gsub(","," OR ")}) AND budget_period_start_iso_date:[#{settings.current_first_day_of_financial_year}T00:00:00Z TO *] AND budget_period_end_iso_date:[* TO #{settings.current_last_day_of_financial_year}T00:00:00Z] AND recipient_country_code:AL&fl=recipient_country_code,budget_period_start_iso_date,budget_period_end_iso_date,budget_value_gbp,recipient_country_name,sector_code,sector_percentage,hierarchy,related_activity_type,related_activity_ref&rows=50000"
    count = 20
    #newApiCall = settings.oipa_api_url_other + "budget?q=iati_identifier:(GB-1-204158* OR GB-GOV-1-301371* OR GB-GOV-1-301433* OR GB-GOV-1-301465* OR GB-GOV-1-301511* OR GB-GOV-1-301527* OR GB-GOV-1-300420* OR GB-GOV-1-300708* OR GB-GOV-1-301019* OR GB-GOV-1-301095*) AND hierarchy:2 AND reporting_org_ref:(#{settings.goverment_department_ids.gsub(","," OR ")}) AND recipient_country_code:*&fl=budget_value,activity_status_code,iati_identifier,budget.period-start.quarter,budget.period-end.quarter,recipient_country_code,budget_period_start_iso_date,budget_period_end_iso_date,budget_value_gbp,recipient_country_name,sector_code,sector_percentage,hierarchy,related_activity_type,related_activity_ref,related_budget_value,related_budget_period_start_quarter,related_budget_period_end_quarter,related_budget_period_start_iso_date,related_budget_period_end_iso_date&start=0&rows=#{count}"
    newApiCall = settings.oipa_api_url_other + "budget?q=reporting_org_ref:(#{settings.goverment_department_ids.gsub(","," OR ")}) AND recipient_country_code:*&fl=budget_value,activity_status_code,iati_identifier,budget.period-start.quarter,budget.period-end.quarter,recipient_country_code,budget_period_start_iso_date,budget_period_end_iso_date,budget_value_gbp,recipient_country_name,sector_code,sector_percentage,hierarchy,related_activity_type,related_activity_ref,related_budget_value,related_budget_period_start_quarter,related_budget_period_end_quarter,related_budget_period_start_iso_date,related_budget_period_end_iso_date&start=0&rows=#{count}"
    ##pagination stuff
    puts newApiCall
    page = 1
    page = page.to_i - 1
    finalPage = page * count
    ######
    pd = RestClient.get newApiCall
    pd  = JSON.parse(pd)
    numOActivities = pd['response']['numFound'].to_i
    puts ('Number of activities: ' + numOActivities.to_s)
    pulledData = pd['response']['docs'] 
    if (numOActivities > count)
      pages = (numOActivities.to_f/count).ceil
      for p in 2..pages do
          p = p - 1
          finalPage = p * count
          tempData = JSON.parse(RestClient.get settings.oipa_api_url_other + "budget?q=reporting_org_ref:(#{settings.goverment_department_ids.gsub(","," OR ")}) AND recipient_country_code:*&fl=budget_value,activity_status_code,iati_identifier,budget.period-start.quarter,budget.period-end.quarter,recipient_country_code,budget_period_start_iso_date,budget_period_end_iso_date,budget_value_gbp,recipient_country_name,sector_code,sector_percentage,hierarchy,related_activity_type,related_activity_ref,related_budget_value,related_budget_period_start_quarter,related_budget_period_end_quarter,related_budget_period_start_iso_date,related_budget_period_end_iso_date,&start=#{finalPage}&rows=#{count}")
          tempData = tempData['response']['docs']
          tempData.each do |item|
            if item.has_key?('activity_status_code')
              if item['activity_status_code'].to_i == 2
                pulledData.push(item)
              end
            end
          end
      end
    end
    puts ('Activity count: ' + pulledData.count.to_s)
    sectorHierarchy = JSON.parse(File.read('data/sectorHierarchies.json'))
    countryHash = {}
    projectDataHash = {}
    projectTracker = []
    countryProjecttracker = {}
    currentFinYear = financial_year
    firstDayOfFinYear = first_day_of_financial_year(DateTime.now)
    lastDayOfFinYear = last_day_of_financial_year(DateTime.now)
    pulledData.each do |element|
      if element.has_key?('activity_status_code')
        if element['activity_status_code'].to_i == 2
          tempTotalBudget = 0
          if element.has_key?('budget_value')
            element['budget_value_gbp'].each_with_index do |data, index|
              if(element['budget_period_start_iso_date'][index].to_datetime >= firstDayOfFinYear && element['budget_period_end_iso_date'][index].to_datetime <= lastDayOfFinYear)
                tempTotalBudget = tempTotalBudget + data.to_f
              end
            end
          end
          # begin
          #   if element.has_key?('budget_value')
          #     element['budget_value'].each_with_index do |data, index|
          #       tStart = Time.parse(element['budget_period_start_iso_date'][index])
          #       fyStart = if element['budget.period-start.quarter'][index].to_i == 1 then tStart.year - 1 else tStart.year end
          #       tEnd = Time.parse(element['budget_period_end_iso_date'][index])
          #       fyEnd = if element['budget.period-end.quarter'][index].to_i == 1 then tEnd.year - 1 else tEnd.year end
          #       if fyStart <= currentFinYear && fyEnd >= currentFinYear
          #         tempTotalBudget = tempTotalBudget + data.to_f
          #       else
          #         puts element['budget_period_start_iso_date'][index]
          #         #puts ('start year: ' + fyStart.to_s + ' and end year: ' + fyEnd.to_s + ' and current system fin year: ' + currentFinYear.to_s)
          #       end
          #     end
          #   end
          # rescue
          #   puts 'Issue found: '
          #   puts element
          # end
          # if element.has_key?('related_budget_value')
          #   element['related_budget_value'].each_with_index do |data, index|
          #     tStart = Time.parse(element['related_budget_period_start_iso_date'][index])
          #     fyStart = if element['related_budget_period_start_quarter'][index].to_i == 1 then tStart.year - 1 else tStart.year end
          #     tEnd = Time.parse(element['related_budget_period_end_iso_date'][index])
          #     fyEnd = if element['related_budget_period_end_quarter'][index].to_i == 1 then tEnd.year - 1 else tEnd.year end
          #     if fyStart <= currentFinYear || fyEnd >= currentFinYear
          #       tempTotalBudget = tempTotalBudget + data.to_f
          #     end
          #   end
          # end
          #######################################
          if(element['hierarchy'] == 2 && element['reporting_org_ref'].to_s == 'GB-GOV-1')
            if element.has_key?('related_activity_type')
              if(!element['related_activity_type'].index('1').nil?)
                if(countryProjecttracker.has_key?(element["recipient_country_code"].first))
                  if(countryProjecttracker[element["recipient_country_code"].first].index(element['related_activity_ref'][element['related_activity_type'].index('1')].to_s).nil?)
                    countryProjecttracker[element["recipient_country_code"].first].push(element['related_activity_ref'][element['related_activity_type'].index('1')].to_s)
                    projectDataHash[element["recipient_country_code"].first]["projects"] = projectDataHash[element["recipient_country_code"].first]["projects"] + 1
                    projectDataHash[element["recipient_country_code"].first]["budget"] = projectDataHash[element["recipient_country_code"].first]["budget"] + tempTotalBudget
                  else
                    projectDataHash[element["recipient_country_code"].first]["budget"] = projectDataHash[element["recipient_country_code"].first]["budget"] + tempTotalBudget
                  end
                else
                  countryProjecttracker[element["recipient_country_code"].first] = []
                  countryProjecttracker[element["recipient_country_code"].first].push(element['related_activity_ref'][element['related_activity_type'].index('1')].to_s)
                  projectDataHash[element["recipient_country_code"].first] = {}
                  projectDataHash[element["recipient_country_code"].first]["country"] = element.has_key?('recipient_country_name') ? element["recipient_country_name"].first : 'N/A'
                  projectDataHash[element["recipient_country_code"].first]["id"] = element["recipient_country_code"].first
                  projectDataHash[element["recipient_country_code"].first]["projects"] = 1
                  projectDataHash[element["recipient_country_code"].first]["budget"] = tempTotalBudget
                  projectDataHash[element["recipient_country_code"].first]["flag"] = '/images/flags/' + element["recipient_country_code"].first.downcase + '.png'
                end
              else
                puts ('faileddddd')
                ###new logic
              end
            end
          elsif(element['reporting_org_ref'].to_s != 'GB-GOV-1')
            if element.has_key?('recipient_country_code')
              element['recipient_country_code'].each_with_index do |c, index|
                if(countryProjecttracker.has_key?(c))
                  if(countryProjecttracker[c].index(element['iati_identifier'].to_s).nil?)
                    countryProjecttracker[c].push(element['iati_identifier'].to_s)
                    projectDataHash[c]["projects"] = projectDataHash[c]["projects"] + 1
                    projectDataHash[c]["budget"] = projectDataHash[c]["budget"] + ((tempTotalBudget * element['recipient_country_percentage'][index].to_f) / 100)
                  else
                    projectDataHash[c]["budget"] = projectDataHash[c]["budget"] + ((tempTotalBudget * element['recipient_country_percentage'][index].to_f) / 100)
                  end
                else
                  countryProjecttracker[c] = []
                  countryProjecttracker[c].push(element['iati_identifier'].to_s)
                  projectDataHash[c] = {}
                  projectDataHash[c]["country"] = element.has_key?('recipient_country_name') ? element["recipient_country_name"][index] : 'N/A'
                  projectDataHash[c]["id"] = begin element["recipient_country_code"][index] rescue '' end
                  projectDataHash[c]["projects"] = 1
                  projectDataHash[c]["budget"] = tempTotalBudget
                  projectDataHash[c]["flag"] = '/images/flags/' + element["recipient_country_code"].first.downcase + '.png'
                end
              end
            end
            ####
            # if(countryProjecttracker.has_key?(element["recipient_country_code"].first))
            #   if(countryProjecttracker[element["recipient_country_code"].first].index(element['iati_identifier'].to_s).nil?)
            #     countryProjecttracker[element["recipient_country_code"].first].push(element['iati_identifier'].to_s)
            #     projectDataHash[element["recipient_country_code"].first]["projects"] = projectDataHash[element["recipient_country_code"].first]["projects"] + 1
            #     projectDataHash[element["recipient_country_code"].first]["budget"] = projectDataHash[element["recipient_country_code"].first]["budget"] + tempTotalBudget
            #   else
            #     projectDataHash[element["recipient_country_code"].first]["budget"] = projectDataHash[element["recipient_country_code"].first]["budget"] + tempTotalBudget
            #   end
            # else
            #   countryProjecttracker[element["recipient_country_code"].first] = []
            #   countryProjecttracker[element["recipient_country_code"].first].push(element['iati_identifier'].to_s)
            #   projectDataHash[element["recipient_country_code"].first] = {}
            #   projectDataHash[element["recipient_country_code"].first]["country"] = element.has_key?('recipient_country_name') ? element["recipient_country_name"].first : 'N/A'
            #   projectDataHash[element["recipient_country_code"].first]["id"] = element["recipient_country_code"].first
            #   projectDataHash[element["recipient_country_code"].first]["projects"] = 1
            #   projectDataHash[element["recipient_country_code"].first]["budget"] = tempTotalBudget
            #   projectDataHash[element["recipient_country_code"].first]["flag"] = '/images/flags/' + element["recipient_country_code"].first.downcase + '.png'
            # end
          end
          ######################################
          if(!countryHash.has_key?(element['recipient_country_code'].first))
            countryHash[element['recipient_country_code'].first] = {}
          end
          #highLvlSectorData = sectorHierarchy.select{|s| s['Code (L3)'].to_i == catCode.to_i}
          if element.has_key?('sector_code')
            element['sector_code'].each_with_index do |data, index|
              if !sectorHierarchy.find_index{|k,_| k['Code (L3)'].to_i == data.to_i}.nil?
                selectedHiLvlSectorData = sectorHierarchy.find{|k,_| k['Code (L3)'].to_i == data.to_i}
                if(countryHash[element['recipient_country_code'].first].has_key?(selectedHiLvlSectorData['High Level Sector Description']))
                  if(element.has_key?('sector_percentage'))
                    countryHash[element['recipient_country_code'].first][selectedHiLvlSectorData['High Level Sector Description']]['budget'] = countryHash[element['recipient_country_code'].first][selectedHiLvlSectorData['High Level Sector Description']]['budget'] + (tempTotalBudget * (element['sector_percentage'][index].to_f/100))
                  else
                    countryHash[element['recipient_country_code'].first][selectedHiLvlSectorData['High Level Sector Description']]['budget'] = countryHash[element['recipient_country_code'].first][selectedHiLvlSectorData['High Level Sector Description']]['budget'] + tempTotalBudget
                  end
                else
                  countryHash[element['recipient_country_code'].first][selectedHiLvlSectorData['High Level Sector Description']] = {}
                  countryHash[element['recipient_country_code'].first][selectedHiLvlSectorData['High Level Sector Description']]['code'] = selectedHiLvlSectorData['High Level Code (L1)'].to_i
                  countryHash[element['recipient_country_code'].first][selectedHiLvlSectorData['High Level Sector Description']]['name'] = selectedHiLvlSectorData['High Level Sector Description']
                  if(element.has_key?('sector_percentage'))
                    countryHash[element['recipient_country_code'].first][selectedHiLvlSectorData['High Level Sector Description']]['budget'] = (tempTotalBudget * (element['sector_percentage'][index].to_f/100))
                  else
                    countryHash[element['recipient_country_code'].first][selectedHiLvlSectorData['High Level Sector Description']]['budget'] = tempTotalBudget
                  end
                end
              end
            end
          end
        end
      end
      #######################
      # if (element.has_key?('recipient_country_code'))
      #   tempTotalBudget = 0
      #   element['budget_period_start_iso_date'].each_with_index do |data, index|
      #       if(data.to_datetime >= settings.current_first_day_of_financial_year && element['budget_period_end_iso_date'][index].to_datetime <= settings.current_last_day_of_financial_year)
      #           tempTotalBudget = tempTotalBudget + element['budget_value_gbp'][index].to_f
      #       end
      #   end
      #   ## Prepare projects hash
      #   if(element['hierarchy'] == 2)
      #     if(!element['related_activity_type'].index('1').nil?)
      #       if(countryProjecttracker.has_key?(element["recipient_country_code"].first))
      #         if(countryProjecttracker[element["recipient_country_code"].first].index(element['related_activity_ref'][element['related_activity_type'].index('1')].to_s).nil?)
      #           countryProjecttracker[element["recipient_country_code"].first].push(element['related_activity_ref'][element['related_activity_type'].index('1')].to_s)
      #           projectDataHash[element["recipient_country_code"].first]["projects"] = projectDataHash[element["recipient_country_code"].first]["projects"] + 1
      #           projectDataHash[element["recipient_country_code"].first]["budget"] = projectDataHash[element["recipient_country_code"].first]["budget"] + tempTotalBudget
      #         else
      #           projectDataHash[element["recipient_country_code"].first]["budget"] = projectDataHash[element["recipient_country_code"].first]["budget"] + tempTotalBudget
      #         end
      #       else
      #         countryProjecttracker[element["recipient_country_code"].first] = []
      #         countryProjecttracker[element["recipient_country_code"].first].push(element['related_activity_ref'][element['related_activity_type'].index('1')].to_s)
      #         projectDataHash[element["recipient_country_code"].first] = {}
      #         projectDataHash[element["recipient_country_code"].first]["country"] = element.has_key?('recipient_country_name') ? element["recipient_country_name"].first : 'N/A'
      #         projectDataHash[element["recipient_country_code"].first]["id"] = element["recipient_country_code"].first
      #         projectDataHash[element["recipient_country_code"].first]["projects"] = 1
      #         projectDataHash[element["recipient_country_code"].first]["budget"] = tempTotalBudget
      #         projectDataHash[element["recipient_country_code"].first]["flag"] = '/images/flags/' + element["recipient_country_code"].first.downcase + '.png'
      #       end
      #     else
      #       puts ('faileddddd')
      #       ###new logic
      #     end
      #   end
      #   ##
      #   if(!countryHash.has_key?(element['recipient_country_code'].first))
      #     countryHash[element['recipient_country_code'].first] = {}
      #   end
      #   #highLvlSectorData = sectorHierarchy.select{|s| s['Code (L3)'].to_i == catCode.to_i}
      #   if element.has_key?('sector_code')
      #     element['sector_code'].each_with_index do |data, index|
      #       if !sectorHierarchy.find_index{|k,_| k['Code (L3)'].to_i == data.to_i}.nil?
      #         selectedHiLvlSectorData = sectorHierarchy.find{|k,_| k['Code (L3)'].to_i == data.to_i}
      #         if(countryHash[element['recipient_country_code'].first].has_key?(selectedHiLvlSectorData['High Level Sector Description']))
      #           if(element.has_key?('sector_percentage'))
      #             countryHash[element['recipient_country_code'].first][selectedHiLvlSectorData['High Level Sector Description']]['budget'] = countryHash[element['recipient_country_code'].first][selectedHiLvlSectorData['High Level Sector Description']]['budget'] + (tempTotalBudget * (element['sector_percentage'][index].to_f/100))
      #           else
      #             countryHash[element['recipient_country_code'].first][selectedHiLvlSectorData['High Level Sector Description']]['budget'] = countryHash[element['recipient_country_code'].first][selectedHiLvlSectorData['High Level Sector Description']]['budget'] + tempTotalBudget
      #           end
      #         else
      #           countryHash[element['recipient_country_code'].first][selectedHiLvlSectorData['High Level Sector Description']] = {}
      #           countryHash[element['recipient_country_code'].first][selectedHiLvlSectorData['High Level Sector Description']]['code'] = selectedHiLvlSectorData['High Level Code (L1)'].to_i
      #           countryHash[element['recipient_country_code'].first][selectedHiLvlSectorData['High Level Sector Description']]['name'] = selectedHiLvlSectorData['High Level Sector Description']
      #           if(element.has_key?('sector_percentage'))
      #             countryHash[element['recipient_country_code'].first][selectedHiLvlSectorData['High Level Sector Description']]['budget'] = (tempTotalBudget * (element['sector_percentage'][index].to_f/100))
      #           else
      #             countryHash[element['recipient_country_code'].first][selectedHiLvlSectorData['High Level Sector Description']]['budget'] = tempTotalBudget
      #           end
      #         end
      #       end
      #     end
      #   end
      # end
    end
    finalOutput = Array.new
    finalOutput.push(projectDataHash.to_s.gsub("[", "").gsub("]", "").gsub("=>",":").gsub("}}, {","},"))
    finalOutput.push(projectDataHash)
    countryHash.each do |key|
      countryHash[key[0]] = key[1].sort_by{ |x, y| -y["budget"] }
    end
    countryHash
    output = {}
    output['map_data'] = finalOutput
    output['countryHash'] = countryHash
    output['xx'] = countryProjecttracker
    output
  end
  ###############################
  #Serve the aid by location country page table data
  def generateCountryDatav3()
    #newApiCall = settings.oipa_api_url_other + "budget?q=reporting_org_ref:(#{settings.goverment_department_ids.gsub(","," OR ")}) AND budget_period_start_iso_date:[#{settings.current_first_day_of_financial_year}T00:00:00Z TO *] AND budget_period_end_iso_date:[* TO #{settings.current_last_day_of_financial_year}T00:00:00Z] AND recipient_country_code:AL&fl=recipient_country_code,budget_period_start_iso_date,budget_period_end_iso_date,budget_value_gbp,recipient_country_name,sector_code,sector_percentage,hierarchy,related_activity_type,related_activity_ref&rows=50000"
    count = 20
    #newApiCall = settings.oipa_api_url_other + "budget?q=iati_identifier:(GB-1-204158* OR GB-GOV-1-301371* OR GB-GOV-1-301433* OR GB-GOV-1-301465* OR GB-GOV-1-301511* OR GB-GOV-1-301527* OR GB-GOV-1-300420* OR GB-GOV-1-300708* OR GB-GOV-1-301019* OR GB-GOV-1-301095*) AND hierarchy:2 AND reporting_org_ref:(#{settings.goverment_department_ids.gsub(","," OR ")}) AND recipient_country_code:*&fl=budget_value,activity_status_code,iati_identifier,budget.period-start.quarter,budget.period-end.quarter,recipient_country_code,budget_period_start_iso_date,budget_period_end_iso_date,budget_value_gbp,recipient_country_name,sector_code,sector_percentage,hierarchy,related_activity_type,related_activity_ref,related_budget_value,related_budget_period_start_quarter,related_budget_period_end_quarter,related_budget_period_start_iso_date,related_budget_period_end_iso_date&start=0&rows=#{count}"
    newApiCall = settings.oipa_api_url_other + "budget?q=reporting_org_ref:(#{settings.goverment_department_ids.gsub(","," OR ")}) AND recipient_country_code:NE&fl=recipient_country_percentage,budget_value,activity_status_code,iati_identifier,budget.period-start.quarter,budget.period-end.quarter,recipient_country_code,budget_period_start_iso_date,budget_period_end_iso_date,budget_value_gbp,recipient_country_name,sector_code,sector_percentage,hierarchy,related_activity_type,related_activity_ref,related_budget_value,related_budget_period_start_quarter,related_budget_period_end_quarter,related_budget_period_start_iso_date,related_budget_period_end_iso_date&start=0&rows=#{count}"
    ##pagination stuff
    puts newApiCall
    page = 1
    page = page.to_i - 1
    finalPage = page * count
    ######
    pd = RestClient.get newApiCall
    pd  = JSON.parse(pd)
    numOActivities = pd['response']['numFound'].to_i
    puts ('Number of activities: ' + numOActivities.to_s)
    pulledData = pd['response']['docs'] 
    if (numOActivities > count)
      pages = (numOActivities.to_f/count).ceil
      for p in 2..pages do
          p = p - 1
          finalPage = p * count
          tempData = JSON.parse(RestClient.get settings.oipa_api_url_other + "budget?q=reporting_org_ref:(#{settings.goverment_department_ids.gsub(","," OR ")}) AND recipient_country_code:NE&fl=recipient_country_percentage,budget_value,activity_status_code,iati_identifier,budget.period-start.quarter,budget.period-end.quarter,recipient_country_code,budget_period_start_iso_date,budget_period_end_iso_date,budget_value_gbp,recipient_country_name,sector_code,sector_percentage,hierarchy,related_activity_type,related_activity_ref,related_budget_value,related_budget_period_start_quarter,related_budget_period_end_quarter,related_budget_period_start_iso_date,related_budget_period_end_iso_date,&start=#{finalPage}&rows=#{count}")
          tempData = tempData['response']['docs']
          tempData.each do |item|
            if item.has_key?('activity_status_code')
              if item['activity_status_code'].to_i == 2
                pulledData.push(item)
              end
            end
          end
      end
    end
    puts ('Activity count: ' + pulledData.count.to_s)
    sectorHierarchy = JSON.parse(File.read('data/sectorHierarchies.json'))
    countryHash = {}
    projectDataHash = {}
    projectTracker = []
    countryProjecttracker = {}
    currentFinYear = financial_year
    firstDayOfFinYear = first_day_of_financial_year(DateTime.now)
    lastDayOfFinYear = last_day_of_financial_year(DateTime.now)
    pulledData.each do |element|
      if element.has_key?('activity_status_code')
        if element['activity_status_code'].to_i == 2
          tempTotalBudget = 0
          if element.has_key?('budget_value')
            element['budget_value_gbp'].each_with_index do |data, index|
              if(element['budget_period_start_iso_date'][index].to_datetime >= firstDayOfFinYear && element['budget_period_end_iso_date'][index].to_datetime <= lastDayOfFinYear)
                tempTotalBudget = tempTotalBudget + data.to_f
              end
            end
          end
          #######################################
          if(element['hierarchy'] == 2 && element['reporting_org_ref'].to_s == 'GB-GOV-1')
            if element.has_key?('related_activity_type')
              if(!element['related_activity_type'].index('1').nil?)
                if(countryProjecttracker.has_key?(element["recipient_country_code"].first))
                  if(countryProjecttracker[element["recipient_country_code"].first].index(element['related_activity_ref'][element['related_activity_type'].index('1')].to_s).nil?)
                    countryProjecttracker[element["recipient_country_code"].first].push(element['related_activity_ref'][element['related_activity_type'].index('1')].to_s)
                    projectDataHash[element["recipient_country_code"].first]["projects"] = projectDataHash[element["recipient_country_code"].first]["projects"] + 1
                    projectDataHash[element["recipient_country_code"].first]["budget"] = projectDataHash[element["recipient_country_code"].first]["budget"] + tempTotalBudget
                  else
                    projectDataHash[element["recipient_country_code"].first]["budget"] = projectDataHash[element["recipient_country_code"].first]["budget"] + tempTotalBudget
                  end
                else
                  countryProjecttracker[element["recipient_country_code"].first] = []
                  countryProjecttracker[element["recipient_country_code"].first].push(element['related_activity_ref'][element['related_activity_type'].index('1')].to_s)
                  projectDataHash[element["recipient_country_code"].first] = {}
                  projectDataHash[element["recipient_country_code"].first]["country"] = element.has_key?('recipient_country_name') ? element["recipient_country_name"].first : 'N/A'
                  projectDataHash[element["recipient_country_code"].first]["id"] = element["recipient_country_code"].first
                  projectDataHash[element["recipient_country_code"].first]["projects"] = 1
                  projectDataHash[element["recipient_country_code"].first]["budget"] = tempTotalBudget
                  projectDataHash[element["recipient_country_code"].first]["flag"] = '/images/flags/' + element["recipient_country_code"].first.downcase + '.png'
                end
              else
                puts ('faileddddd')
                ###new logic
              end
            end
          elsif(element['reporting_org_ref'].to_s != 'GB-GOV-1')
            if element.has_key?('recipient_country_code') and tempTotalBudget > 0
              if element['recipient_country_code'].length() > 1
                element['recipient_country_code'].each_with_index do |c, index|
                  if(countryProjecttracker.has_key?(c))
                    if(countryProjecttracker[c].index(element['iati_identifier'].to_s).nil?)
                      countryProjecttracker[c].push(element['iati_identifier'].to_s)
                      projectDataHash[c]["projects"] = projectDataHash[c]["projects"] + 1
                      begin
                        projectDataHash[c]["budget"] = projectDataHash[c]["budget"] + ((tempTotalBudget * element['recipient_country_percentage'][index].to_f) / 100)
                      rescue
                        puts 'staged----'
                        puts 'temp total budget:' + tempTotalBudget.to_s
                        puts projectDataHash[c]["budget"]
                        puts element['iati_identifier']
                        projectDataHash[c]["budget"] = projectDataHash[c]["budget"] + 0
                      end
                    else
                      projectDataHash[c]["budget"] = projectDataHash[c]["budget"] + ((tempTotalBudget * element['recipient_country_percentage'][index].to_f) / 100)
                    end
                  else
                    countryProjecttracker[c] = []
                    countryProjecttracker[c].push(element['iati_identifier'].to_s)
                    projectDataHash[c] = {}
                    projectDataHash[c]["country"] = element.has_key?('recipient_country_name') ? element["recipient_country_name"][index] : 'N/A'
                    projectDataHash[c]["id"] = begin element["recipient_country_code"][index] rescue '' end
                    projectDataHash[c]["projects"] = 1
                    projectDataHash[c]["budget"] = tempTotalBudget
                    projectDataHash[c]["flag"] = '/images/flags/' + element["recipient_country_code"].first.downcase + '.png'
                  end
                end
              else
                c = element['recipient_country_code'].first
                if(countryProjecttracker.has_key?(c))
                  if(countryProjecttracker[c].index(element['iati_identifier'].to_s).nil?)
                    countryProjecttracker[c].push(element['iati_identifier'].to_s)
                    projectDataHash[c]["projects"] = projectDataHash[c]["projects"] + 1
                    projectDataHash[c]["budget"] = projectDataHash[c]["budget"] + tempTotalBudget 
                  else
                    projectDataHash[c]["budget"] = projectDataHash[c]["budget"] + tempTotalBudget
                  end
                else
                  countryProjecttracker[c] = []
                  countryProjecttracker[c].push(element['iati_identifier'].to_s)
                  projectDataHash[c] = {}
                  projectDataHash[c]["country"] = element.has_key?('recipient_country_name') ? element["recipient_country_name"].first : 'N/A'
                  projectDataHash[c]["id"] = begin element["recipient_country_code"].first rescue '' end
                  projectDataHash[c]["projects"] = 1
                  projectDataHash[c]["budget"] = tempTotalBudget
                  projectDataHash[c]["flag"] = '/images/flags/' + element["recipient_country_code"].first.downcase + '.png'
                end
              end
            end
          end
        end
      end
    end
    finalOutput = Array.new
    finalOutput.push(projectDataHash.to_s.gsub("[", "").gsub("]", "").gsub("=>",":").gsub("}}, {","},"))
    finalOutput.push(projectDataHash)
    output = {}
    output['map_data'] = finalOutput
    output
  end
  ###############################
  ###############################
  def generateCountryDatav4()
    #newApiCall = settings.oipa_api_url_other + "budget?q=reporting_org_ref:(#{settings.goverment_department_ids.gsub(","," OR ")}) AND budget_period_start_iso_date:[#{settings.current_first_day_of_financial_year}T00:00:00Z TO *] AND budget_period_end_iso_date:[* TO #{settings.current_last_day_of_financial_year}T00:00:00Z] AND recipient_country_code:AL&fl=recipient_country_code,budget_period_start_iso_date,budget_period_end_iso_date,budget_value_gbp,recipient_country_name,sector_code,sector_percentage,hierarchy,related_activity_type,related_activity_ref&rows=50000"
    count = 20
    #newApiCall = settings.oipa_api_url_other + "budget?q=iati_identifier:(GB-1-204158* OR GB-GOV-1-301371* OR GB-GOV-1-301433* OR GB-GOV-1-301465* OR GB-GOV-1-301511* OR GB-GOV-1-301527* OR GB-GOV-1-300420* OR GB-GOV-1-300708* OR GB-GOV-1-301019* OR GB-GOV-1-301095*) AND hierarchy:2 AND reporting_org_ref:(#{settings.goverment_department_ids.gsub(","," OR ")}) AND recipient_country_code:*&fl=budget_value,activity_status_code,iati_identifier,budget.period-start.quarter,budget.period-end.quarter,recipient_country_code,budget_period_start_iso_date,budget_period_end_iso_date,budget_value_gbp,recipient_country_name,sector_code,sector_percentage,hierarchy,related_activity_type,related_activity_ref,related_budget_value,related_budget_period_start_quarter,related_budget_period_end_quarter,related_budget_period_start_iso_date,related_budget_period_end_iso_date&start=0&rows=#{count}"
    newApiCall = settings.oipa_api_url_other + "budget?q=activity_status_code:2 AND participating_org_ref:GB-GOV-* AND reporting_org_ref:(#{settings.goverment_department_ids.gsub(","," OR ")}) AND recipient_country_code:*&fl=reporting_org_ref,recipient_country_percentage,budget_value,activity_status_code,iati_identifier,budget.period-start.quarter,budget.period-end.quarter,recipient_country_code,budget_period_start_iso_date,budget_period_end_iso_date,budget_value_gbp,recipient_country_name,sector_code,sector_percentage,hierarchy,related_activity_type,related_activity_ref,related_budget_value,related_budget_period_start_quarter,related_budget_period_end_quarter,related_budget_period_start_iso_date,related_budget_period_end_iso_date&start=0&rows=#{count}"
    ##pagination stuff
    puts newApiCall
    page = 1
    page = page.to_i - 1
    finalPage = page * count
    ######
    pd = RestClient.get newApiCall
    pd  = JSON.parse(pd)
    numOActivities = pd['response']['numFound'].to_i
    puts ('Number of activities: ' + numOActivities.to_s)
    pulledData = pd['response']['docs'] 
    if (numOActivities > count)
      puts 'activity count more than 20'
      pages = (numOActivities.to_f/count).ceil
      for p in 2..pages do
          p = p - 1
          finalPage = p * count
          puts settings.oipa_api_url_other + "budget?q=activity_status_code:2 AND participating_org_ref:GB-GOV-* AND reporting_org_ref:(#{settings.goverment_department_ids.gsub(","," OR ")}) AND recipient_country_code:*&fl=reporting_org_ref,recipient_country_percentage,budget_value,activity_status_code,iati_identifier,budget.period-start.quarter,budget.period-end.quarter,recipient_country_code,budget_period_start_iso_date,budget_period_end_iso_date,budget_value_gbp,recipient_country_name,sector_code,sector_percentage,hierarchy,related_activity_type,related_activity_ref,related_budget_value,related_budget_period_start_quarter,related_budget_period_end_quarter,related_budget_period_start_iso_date,related_budget_period_end_iso_date,&start=#{finalPage}&rows=#{count}"
          tempData = JSON.parse(RestClient.get settings.oipa_api_url_other + "budget?q=activity_status_code:2 AND participating_org_ref:GB-GOV-* AND reporting_org_ref:(#{settings.goverment_department_ids.gsub(","," OR ")}) AND recipient_country_code:*&fl=reporting_org_ref,recipient_country_percentage,budget_value,activity_status_code,iati_identifier,budget.period-start.quarter,budget.period-end.quarter,recipient_country_code,budget_period_start_iso_date,budget_period_end_iso_date,budget_value_gbp,recipient_country_name,sector_code,sector_percentage,hierarchy,related_activity_type,related_activity_ref,related_budget_value,related_budget_period_start_quarter,related_budget_period_end_quarter,related_budget_period_start_iso_date,related_budget_period_end_iso_date,&start=#{finalPage}&rows=#{count}")
          tempData = tempData['response']['docs']
          tempData.each do |item|
            if item.has_key?('activity_status_code')
              if item['activity_status_code'].to_i == 2
                pulledData.push(item)
              end
            end
          end
      end
    end
    puts ('Activity count: ' + pulledData.count.to_s)
    sectorHierarchy = JSON.parse(File.read('data/sectorHierarchies.json'))
    countryHash = {}
    projectDataHash = {}
    projectTracker = []
    countryProjecttracker = {}
    currentFinYear = financial_year
    firstDayOfFinYear = first_day_of_financial_year(DateTime.now)
    lastDayOfFinYear = last_day_of_financial_year(DateTime.now)
    ##
    fcdoCountryProjectTracker = {}
    countryDataHash = {}
    ##
    pulledData.each do |element|
      File.open('data/cache/xx.txt', "a") { |f| f.puts element }	
      tempTotalBudget = 0
      if element.has_key?('activity_status_code')
        if element['activity_status_code'].to_i == 2
          if element.has_key?('budget_value')
            element['budget_value_gbp'].each_with_index do |data, index|
              if(element['budget_period_start_iso_date'][index].to_datetime >= firstDayOfFinYear && element['budget_period_end_iso_date'][index].to_datetime <= lastDayOfFinYear)
                tempTotalBudget = tempTotalBudget + data.to_f
              end
            end
          end
          #######################################
          ####New method starts here
          if(element['hierarchy'] == 2 && element['reporting_org_ref'].to_s == 'GB-GOV-1')
            if element.has_key?('related_activity_type')
              if(!element['related_activity_type'].index('1').nil?)
                if(countryProjecttracker.has_key?(element["recipient_country_code"].first))
                  if(!countryProjecttracker[element["recipient_country_code"].first].index(element['related_activity_ref'].first.to_s).nil?)
                    puts 'country projectr acker has key, fcdo projecrttracker has key. just adding budget'
                    projectDataHash[element["recipient_country_code"].first]["budget"] = projectDataHash[element["recipient_country_code"].first]["budget"] + tempTotalBudget
                  else
                    puts 'country projectr acker has key, fcdo projecrttracker does not have key. adding budget and project'
                    countryProjecttracker[element["recipient_country_code"].first].push(element['related_activity_ref'].first.to_s)
                    projectDataHash[element["recipient_country_code"].first]["projects"] = projectDataHash[element["recipient_country_code"].first]["projects"] + 1
                    projectDataHash[element["recipient_country_code"].first]["budget"] = projectDataHash[element["recipient_country_code"].first]["budget"] + tempTotalBudget
                  end
                else
                  puts 'country projectr acker has no key. newly adding data. also budgets'
                  countryProjecttracker[element["recipient_country_code"].first] = []
                  countryProjecttracker[element["recipient_country_code"].first].push(element['related_activity_ref'].first.to_s)
                  projectDataHash[element["recipient_country_code"].first] = {}
                  projectDataHash[element["recipient_country_code"].first]["country"] = element.has_key?('recipient_country_name') ? element["recipient_country_name"].first : 'N/A'
                  projectDataHash[element["recipient_country_code"].first]["id"] = element["recipient_country_code"].first
                  projectDataHash[element["recipient_country_code"].first]["projects"] = 1
                  projectDataHash[element["recipient_country_code"].first]["budget"] = tempTotalBudget
                  projectDataHash[element["recipient_country_code"].first]["flag"] = '/images/flags/' + element["recipient_country_code"].first.downcase + '.png'
                end
              end
            end
          elsif(element['reporting_org_ref'].to_s != 'GB-GOV-1' && element['hierarchy'] == 1)
            if element.has_key?('recipient_country_code')
              if element['recipient_country_code'].length() > 1
                puts 'non fcdo project found, country exists, total budget beyond 0, more than one recipient country present: ' + element['recipient_country_code'].count().to_s
                element['recipient_country_code'].each_with_index do |c, index|
                  if(projectDataHash.has_key?(c))
                      projectDataHash[c]["projects"] = projectDataHash[c]["projects"] + 1
                      projectDataHash[c]["budget"] = projectDataHash[c]["budget"] + ((tempTotalBudget * element['recipient_country_percentage'][index].to_f) / 100)
                  else
                    puts c + ' and hash valkue: ' + tempTotalBudget.to_s
                    projectDataHash[c] = {}
                    projectDataHash[c]["country"] = element.has_key?('recipient_country_name') ? element["recipient_country_name"][index] : 'N/A'
                    projectDataHash[c]["id"] = c
                    projectDataHash[c]["projects"] = 1
                    projectDataHash[c]["budget"] = ((tempTotalBudget * element['recipient_country_percentage'][index].to_f) / 100)
                    projectDataHash[c]["flag"] = '/images/flags/' + c.downcase + '.png'
                    puts projectDataHash[c]
                  end
                end
              else
                if(projectDataHash.has_key?(element['recipient_country_code'].first))
                  puts 'non fcdo project found, country exists, total budget beyond 0,  one recipient country present, pdh has coyuntry code'
                  projectDataHash[element['recipient_country_code'].first]["projects"] = projectDataHash[element['recipient_country_code'].first]["projects"] + 1
                  projectDataHash[element['recipient_country_code'].first]["budget"] = projectDataHash[element['recipient_country_code'].first]["budget"] + tempTotalBudget
                else
                  puts 'non fcdo project found, country exists, total budget beyond 0,  one recipient country present, pdh does not ahve couyntry code'
                  projectDataHash[element['recipient_country_code'].first] = {}
                  projectDataHash[element['recipient_country_code'].first]["country"] = element.has_key?('recipient_country_name') ? element["recipient_country_name"].first : 'N/A'
                  projectDataHash[element['recipient_country_code'].first]["id"] = element['recipient_country_code'].first
                  projectDataHash[element['recipient_country_code'].first]["projects"] = 1
                  projectDataHash[element['recipient_country_code'].first]["budget"] = tempTotalBudget
                  projectDataHash[element['recipient_country_code'].first]["flag"] = '/images/flags/' + element['recipient_country_code'].first.downcase + '.png'
                end
              end
            end
          end
          ####New method ends here
          #######################################
          # if(element['hierarchy'] == 2 && element['reporting_org_ref'].to_s == 'GB-GOV-1')
          #   if element.has_key?('related_activity_type')
          #     if(!element['related_activity_type'].index('1').nil?)
          #       if(countryProjecttracker.has_key?(element["recipient_country_code"].first))
          #         if(countryProjecttracker[element["recipient_country_code"].first].index(element['related_activity_ref'][element['related_activity_type'].index('1')].to_s).nil?)
          #           countryProjecttracker[element["recipient_country_code"].first].push(element['related_activity_ref'][element['related_activity_type'].index('1')].to_s)
          #           projectDataHash[element["recipient_country_code"].first]["projects"] = projectDataHash[element["recipient_country_code"].first]["projects"] + 1
          #           projectDataHash[element["recipient_country_code"].first]["budget"] = projectDataHash[element["recipient_country_code"].first]["budget"] + tempTotalBudget
          #         else
          #           projectDataHash[element["recipient_country_code"].first]["budget"] = projectDataHash[element["recipient_country_code"].first]["budget"] + tempTotalBudget
          #         end
          #       else
          #         countryProjecttracker[element["recipient_country_code"].first] = []
          #         countryProjecttracker[element["recipient_country_code"].first].push(element['related_activity_ref'][element['related_activity_type'].index('1')].to_s)
          #         projectDataHash[element["recipient_country_code"].first] = {}
          #         projectDataHash[element["recipient_country_code"].first]["country"] = element.has_key?('recipient_country_name') ? element["recipient_country_name"].first : 'N/A'
          #         projectDataHash[element["recipient_country_code"].first]["id"] = element["recipient_country_code"].first
          #         projectDataHash[element["recipient_country_code"].first]["projects"] = 1
          #         projectDataHash[element["recipient_country_code"].first]["budget"] = tempTotalBudget
          #         projectDataHash[element["recipient_country_code"].first]["flag"] = '/images/flags/' + element["recipient_country_code"].first.downcase + '.png'
          #       end
          #     else
          #       puts ('faileddddd')
          #       ###new logic
          #     end
          #   end
          # elsif(element['reporting_org_ref'].to_s != 'GB-GOV-1')
          #   if element.has_key?('recipient_country_code') and tempTotalBudget > 0
          #     if element['recipient_country_code'].length() > 1
          #       element['recipient_country_code'].each_with_index do |c, index|
          #         if(countryProjecttracker.has_key?(c))
          #           if(countryProjecttracker[c].index(element['iati_identifier'].to_s).nil?)
          #             countryProjecttracker[c].push(element['iati_identifier'].to_s)
          #             projectDataHash[c]["projects"] = projectDataHash[c]["projects"] + 1
          #             begin
          #               projectDataHash[c]["budget"] = projectDataHash[c]["budget"] + ((tempTotalBudget * element['recipient_country_percentage'][index].to_f) / 100)
          #             rescue
          #               puts 'staged----'
          #               puts 'temp total budget:' + tempTotalBudget.to_s
          #               puts projectDataHash[c]["budget"]
          #               puts element['iati_identifier']
          #               projectDataHash[c]["budget"] = projectDataHash[c]["budget"] + 0
          #             end
          #           else
          #             projectDataHash[c]["budget"] = projectDataHash[c]["budget"] + ((tempTotalBudget * element['recipient_country_percentage'][index].to_f) / 100)
          #           end
          #         else
          #           countryProjecttracker[c] = []
          #           countryProjecttracker[c].push(element['iati_identifier'].to_s)
          #           projectDataHash[c] = {}
          #           projectDataHash[c]["country"] = element.has_key?('recipient_country_name') ? element["recipient_country_name"][index] : 'N/A'
          #           projectDataHash[c]["id"] = begin element["recipient_country_code"][index] rescue '' end
          #           projectDataHash[c]["projects"] = 1
          #           projectDataHash[c]["budget"] = tempTotalBudget
          #           projectDataHash[c]["flag"] = '/images/flags/' + element["recipient_country_code"].first.downcase + '.png'
          #         end
          #       end
          #     else
          #       c = element['recipient_country_code'].first
          #       if(countryProjecttracker.has_key?(c))
          #         if(countryProjecttracker[c].index(element['iati_identifier'].to_s).nil?)
          #           countryProjecttracker[c].push(element['iati_identifier'].to_s)
          #           projectDataHash[c]["projects"] = projectDataHash[c]["projects"] + 1
          #           projectDataHash[c]["budget"] = projectDataHash[c]["budget"] + tempTotalBudget 
          #         else
          #           projectDataHash[c]["budget"] = projectDataHash[c]["budget"] + tempTotalBudget
          #         end
          #       else
          #         countryProjecttracker[c] = []
          #         countryProjecttracker[c].push(element['iati_identifier'].to_s)
          #         projectDataHash[c] = {}
          #         projectDataHash[c]["country"] = element.has_key?('recipient_country_name') ? element["recipient_country_name"].first : 'N/A'
          #         projectDataHash[c]["id"] = begin element["recipient_country_code"].first rescue '' end
          #         projectDataHash[c]["projects"] = 1
          #         projectDataHash[c]["budget"] = tempTotalBudget
          #         projectDataHash[c]["flag"] = '/images/flags/' + element["recipient_country_code"].first.downcase + '.png'
          #       end
          #     end
          #   end
          # end
        end
      end
    end
    finalOutput = Array.new
    finalOutput.push(projectDataHash.to_s.gsub("[", "").gsub("]", "").gsub("=>",":").gsub("}}, {","},"))
    finalOutput.push(projectDataHash)
    output = {}
    output['map_data'] = finalOutput
    output
  end

  ###############################
  def generateCountryDatav5()
    count = 20
    newApiCall = settings.oipa_api_url_other + "budget?q=hierarchy:1 AND activity_status_code:2 AND participating_org_ref:GB-GOV-* AND reporting_org_ref:(#{settings.goverment_department_ids.gsub(","," OR ")}) AND recipient_country_code:*&fl=reporting_org_ref,recipient_country_percentage,budget_value,activity_status_code,iati_identifier,budget.period-start.quarter,budget.period-end.quarter,recipient_country_code,budget_period_start_iso_date,budget_period_end_iso_date,budget_value_gbp,recipient_country_name,sector_code,sector_percentage,hierarchy,related_activity_type,related_activity_ref,related_budget_value,related_budget_period_start_quarter,related_budget_period_end_quarter,related_budget_period_start_iso_date,related_budget_period_end_iso_date&start=0&rows=#{count}"
    ##pagination stuff
    page = 1
    page = page.to_i - 1
    finalPage = page * count
    ######
    pd = RestClient.get newApiCall
    pd  = JSON.parse(pd)
    numOActivities = pd['response']['numFound'].to_i
    #puts ('Number of activities: ' + numOActivities.to_s)
    pulledData = pd['response']['docs'] 
    if (numOActivities > count)
      pages = (numOActivities.to_f/count).ceil
      for p in 2..pages do
          p = p - 1
          finalPage = p * count
          tempData = JSON.parse(RestClient.get settings.oipa_api_url_other + "budget?q=hierarchy:1 AND activity_status_code:2 AND participating_org_ref:GB-GOV-* AND reporting_org_ref:(#{settings.goverment_department_ids.gsub(","," OR ")}) AND recipient_country_code:*&fl=reporting_org_ref,recipient_country_percentage,budget_value,activity_status_code,iati_identifier,budget.period-start.quarter,budget.period-end.quarter,recipient_country_code,budget_period_start_iso_date,budget_period_end_iso_date,budget_value_gbp,recipient_country_name,sector_code,sector_percentage,hierarchy,related_activity_type,related_activity_ref,related_budget_value,related_budget_period_start_quarter,related_budget_period_end_quarter,related_budget_period_start_iso_date,related_budget_period_end_iso_date,&start=#{finalPage}&rows=#{count}")
          tempData = tempData['response']['docs']
          tempData.each do |item|
            pulledData.push(item)
          end
      end
    end
    puts ('Activity count: ' + pulledData.count.to_s)
    sectorHierarchy = JSON.parse(File.read('data/sectorHierarchies.json'))
    projectDataHash = {}
    currentFinYear = financial_year
    firstDayOfFinYear = first_day_of_financial_year(DateTime.now)
    lastDayOfFinYear = last_day_of_financial_year(DateTime.now)
    ##
    fcdoCountryProjectTracker = {}
    countryDataHash = {}
    ##
    pulledData.each do |element|
      ######New 2.0 version starts here#####
      tempTotalBudget = 0
      ## Process total budget value first
      if(element['reporting_org_ref'].to_s == 'GB-GOV-1')
        if element.has_key?('related_budget_value')
          element['related_budget_value'].each_with_index do |data, index|
            if(element['related_budget_period_start_iso_date'][index].to_datetime >= firstDayOfFinYear && element['related_budget_period_end_iso_date'][index].to_datetime <= lastDayOfFinYear)
              tempTotalBudget = tempTotalBudget + data.to_f
            end
          end
        end
      else
        if element.has_key?('budget_value')
          element['budget_value'].each_with_index do |data, index|
            if(element['budget_period_start_iso_date'][index].to_datetime >= firstDayOfFinYear && element['budget_period_end_iso_date'][index].to_datetime <= lastDayOfFinYear)
              tempTotalBudget = tempTotalBudget + data.to_f
            end
          end
        end
      end
      ## Process project budget and count now
      if element.has_key?('recipient_country_code')
        element['recipient_country_code'].each_with_index do |c, i|
          countryPercentage = element.has_key?('recipient_country_percentage') ? element['recipient_country_percentage'][i].to_f : 100
          countryBudget = tempTotalBudget*countryPercentage/100
          if(projectDataHash.has_key?(c))
            projectDataHash[c]["projects"] = projectDataHash[c]["projects"] + 1
            projectDataHash[c]["budget"] = (projectDataHash[c]["budget"] + countryBudget).round(2)
          else
            projectDataHash[c] = {}
            projectDataHash[c]["country"] = element.has_key?('recipient_country_name') ? element["recipient_country_name"][i] : 'N/A'
            projectDataHash[c]["id"] = c
            projectDataHash[c]["projects"] = 1
            projectDataHash[c]["budget"] = countryBudget.round(2)
            projectDataHash[c]["flag"] = '/images/flags/' + c.downcase + '.png'
          end
        end
      end
      ######New 2.0 version ends here#######
    end
    finalOutput = Array.new
    finalOutput.push(projectDataHash.to_s.gsub("[", "").gsub("]", "").gsub("=>",":").gsub("}}, {","},"))
    finalOutput.push(projectDataHash)
    output = {}
    output['map_data'] = finalOutput
    output
  end
  ###############################
  def generateCountryData()
    current_first_day_of_financial_year = first_day_of_financial_year(DateTime.now)
    current_last_day_of_financial_year = last_day_of_financial_year(DateTime.now)
    sectorBudgets = Oj.load(RestClient.get  api_simple_log(settings.oipa_api_url + "budgets/aggregations/?reporting_organisation_identifier=#{settings.goverment_department_ids}&order_by=recipient_country&group_by=sector,recipient_country&aggregations=value&format=json&budget_period_start=#{current_first_day_of_financial_year}&budget_period_end=#{current_last_day_of_financial_year}"))
    sectorHierarchies = Oj.load(File.read('data/sectorHierarchies.json'))
    sectorBudgets = sectorBudgets["results"]
    sectorBudgets = sectorBudgets.group_by{|key| key["recipient_country"]["code"]}
    sectorBudgets.each do |countryData|
      sectorBudgets[countryData[0]].each do |countryLevelSectorData|
        tempDAC5Code = countryLevelSectorData['sector']['code']
        pullHighLevelSectorData = sectorHierarchies.select{|key| key["Code (L3)"] == tempDAC5Code.to_i}.first
        countryLevelSectorData['sector']['code'] = pullHighLevelSectorData["High Level Code (L1)"]
        countryLevelSectorData['sector']['name'] = pullHighLevelSectorData["High Level Sector Description"]
      end
    end
    countryHash = {}
    sectorBudgets.each do |countryData|
      countryHash[countryData[0]] = {}
      sectorBudgets[countryData[0]].each do |countryLevelSectorData|
        if !countryHash[countryData[0]].key?(countryLevelSectorData['sector']['name'])
          countryHash[countryData[0]][countryLevelSectorData['sector']['name']] = {}
          countryHash[countryData[0]][countryLevelSectorData['sector']['name']]['code'] = countryLevelSectorData['sector']['code']
          countryHash[countryData[0]][countryLevelSectorData['sector']['name']]['name'] = countryLevelSectorData['sector']['name']
          countryHash[countryData[0]][countryLevelSectorData['sector']['name']]['budget'] = countryLevelSectorData['value'].to_i
        else
          countryHash[countryData[0]][countryLevelSectorData['sector']['name']]['budget'] = countryHash[countryData[0]][countryLevelSectorData['sector']['name']]['budget'].to_i + countryLevelSectorData['value'].to_i
        end
      end
    end
    countryHash.each do |key|
      countryHash[key[0]] = key[1].sort_by{ |x, y| -y["budget"] }
    end
    countryHash
  end

  #Provide a list of dependent reporting organisations grouped by country code
  def generateReportingOrgsCountryWise()
    oipa_reporting_orgs = RestClient.get  api_simple_log(settings.oipa_api_url + "activities/aggregations/?format=json&group_by=reporting_organisation,recipient_country&aggregations=count&reporting_organisation_identifier=#{settings.goverment_department_ids}&hierarchy=1&activity_status=2")
    oipa_reporting_orgs = Oj.load(oipa_reporting_orgs)
    oipa_reporting_orgs = oipa_reporting_orgs['results']
    countryHash = {}
    oipa_reporting_orgs.each do |result|
      if !countryHash.key?(result['recipient_country']['code'])
        countryHash[result['recipient_country']['code']] = Array.new
        countryHash[result['recipient_country']['code']].push(result['reporting_organisation']['organisation_identifier'])
      else
        if !countryHash[result['recipient_country']['code']].include?(result['reporting_organisation']['organisation_identifier'])
          countryHash[result['recipient_country']['code']].push(result['reporting_organisation']['organisation_identifier'])
        end
      end
    end
    countryHash
  end

  #Return OGD name based on OGD code
  def returnDepartmentName(deptCode)
    begin
      ogds = Oj.load(File.read('data/OGDs.json'))
      tempOgd = ogds.select{|key, hash| hash["identifiers"].split(",").include?(deptCode)}
      tempOgd.values[0]['name']
    rescue
      puts deptCode
      'N/A'
    end
  end

  def hash_to_csv(data)
      column_names = data.first.keys
      csv_string = CSV.generate do |csv|
          csv << column_names
          data.each do |item|
              csv << item.values
          end
      end
      csv_string
  end

  def get_project_component_data(project)
    components = Array.new
    project['related_activity'].each do |component|
      if(component['ref'].to_s.include? project['iati_identifier'].to_s)
        begin
          pullActivityData = get_h1_project_details(component['ref'])
          componentData = {}
          begin
            componentData['title'] = pullActivityData['title']['narrative'][0]['text']
          rescue
            componentData['title'] = 'N/A'
          end
          begin
            componentData['activityID'] = pullActivityData['iati_identifier']
          rescue
            componentData['title'] = 'N/A'
          end
          dates = pullActivityData['activity_date']
          if (dates.length > 0)
            begin
              if(!dates.select{|activityDate| activityDate['type']['code'] == '2'}.first.nil?)
                componentData['startDate'] = dates.select{|activityDate| activityDate['type']['code'] == '2'}.first['iso_date']
              elsif(!dates.select{|activityDate| activityDate['type']['code'] == '1'}.first.nil?)
                componentData['startDate'] = dates.select{|activityDate| activityDate['type']['code'] == '1'}.first['iso_date']
              else
                componentData['startDate'] = 'N/A'  
              end
            rescue
              componentData['startDate'] = 'N/A'
            end
            begin
              if(!dates.select{|activityDate| activityDate['type']['code'] == '4'}.first.nil?)
                componentData['endDate'] = dates.select{|activityDate| activityDate['type']['code'] == '4'}.first['iso_date']
              elsif(!dates.select{|activityDate| activityDate['type']['code'] == '3'}.first.nil?)
                componentData['endDate'] = dates.select{|activityDate| activityDate['type']['code'] == '3'}.first['iso_date']
              else
                componentData['endDate'] = 'N/A'  
              end
            rescue
              componentData['endDate'] = 'N/A'
            end
          else
            componentData['startDate'] = 'N/A'
            componentData['endDate'] = 'N/A'
          end
          components.push(componentData)
        rescue
          puts 'Component does not exist in OIPA yet.'
        end
      end
    end
    components = components.sort_by{|component| component['activityID'].to_s}
    components
  end

  # Get country bounds for location country page
    def getCountryBoundsForLocation(countryList)
      countryMappedFile = JSON.parse(File.read('data/country_ISO3166_mapping.json'))
      country3DigitCodeList = Array.new
      countryList.each do |key,val|
        if countryMappedFile.has_key?(key.to_s)
          tempHash = {}
          tempHash['extra'] = val
          tempHash['3Code'] = countryMappedFile[key]
          country3DigitCodeList.push(tempHash)
        end
      end
      geoLocationData = ''
      geoJsonData = Array.new
      if country3DigitCodeList != ''
        geoLocationData = JSON.parse(File.read('data/world.json'))
        country3DigitCodeList.each do |countryCode|
          geoLocationData['features'].each do |loc|
            if loc['properties']['ISO_A3'].to_s == countryCode['3Code'].to_s
              tempHash = {}
              tempHash['extra'] = countryCode['extra']
              tempHash['geometry'] = loc['geometry']
              geoJsonData.push(tempHash)
              break
            end
          end
        end
      end
      geoJsonData
    end
end

#----------To be redacted when merger with main solr branch will happen------------
def add_exclusions_to_solr2()
  query = ''
  solrConfig = Oj.load(File.read('data/solr-config.json'))
  if(solrConfig["Exclusions"]["terms"].length > 0)
    query = query + " AND "
    solrConfig['Exclusions']['fields'].each_with_index do |fieldToBeChecked, index|
        if (solrConfig['Exclusions']['fields'].length - 1 == index)
          query = query + '!' + fieldToBeChecked + ':' + '('
            solrConfig['Exclusions']['terms'].each_with_index do |term, index|
                if (solrConfig['Exclusions']['terms'].length - 1 == index)
                  query = query + '"' + term + '"'
                else
                  query = query + '"' + term + '" OR '
                end
            end
            query = query + ")"
        else
          query = query + '!' + fieldToBeChecked + ':' + '('
            solrConfig['Exclusions']['terms'].each_with_index do |term, index|
                if (solrConfig['Exclusions']['terms'].length - 1 == index)
                  query = query + '"' + term + '"'
                else
                  query = query + '"' + term + '" OR '
                end
            end
            query = query + ") AND "
        end
    end
  end
  query
end

def bestActivityDate(activityDates)
  finalDates = {}
  tempStartDate = activityDates.select {|d| d['type']['code'].to_i == 1 || d['type']['code'].to_i == 2}
  puts(tempStartDate)
	if tempStartDate.length > 1
		finalDates['start_date'] = tempStartDate.select{|d| d['type']['code'].to_i == 2}[0]['iso_date']
	elsif tempStartDate.length == 0
		finalDates['start_date'] = 'N/A'
	else
		finalDates['start_date'] = tempStartDate.first['iso_date']
	end
	tempEndDate = activityDates.select {|d| d['type']['code'].to_i == 3 || d['type']['code'].to_i == 4}
	if tempEndDate.length > 1
		finalDates['end_date'] = tempEndDate.select{|d| d['type']['code'].to_i == 4}[0]['iso_date']
	elsif tempEndDate.length == 0
		finalDates['end_date'] = 'N/A'
	else
		finalDates['end_date'] = tempEndDate.first['iso_date']
	end
  finalDates
end

def bestActivityDatev2(activityDates)
  finalDates = {}
  if activityDates.has_key?('activity_date_type')
    # take best start date
    if(!activityDates['activity_date_type'].index('2').nil?)
      finalDates['start_date'] = format_datev2(activityDates['activity_date_iso_date'][activityDates['activity_date_type'].index('2')])
    elsif (!activityDates['activity_date_type'].index('1').nil?)
      finalDates['start_date'] = format_datev2(activityDates['activity_date_iso_date'][activityDates['activity_date_type'].index('1')])
    else
      finalDates['start_date'] = 'N/A'
    end
    if(!activityDates['activity_date_type'].index('4').nil?)
      finalDates['end_date'] = format_datev2(activityDates['activity_date_iso_date'][activityDates['activity_date_type'].index('4')])
    elsif (!activityDates['activity_date_type'].index('3').nil?)
      finalDates['end_date'] = format_datev2(activityDates['activity_date_iso_date'][activityDates['activity_date_type'].index('3')])
    else
      finalDates['end_date'] = 'N/A'
    end
  else
    finalDates['start_date'] = 'N/A'
    finalDates['end_date'] = 'N/A'
  end
  #finalDates
  ########################
  # tempStartDate = activityDates.select {|d| d['type']['code'].to_i == 1 || d['type']['code'].to_i == 2}
  # puts(tempStartDate)
	# if tempStartDate.length > 1
	# 	finalDates['start_date'] = tempStartDate.select{|d| d['type']['code'].to_i == 2}[0]['iso_date']
	# elsif tempStartDate.length == 0
	# 	finalDates['start_date'] = 'N/A'
	# else
	# 	finalDates['start_date'] = tempStartDate.first['iso_date']
	# end
	# tempEndDate = activityDates.select {|d| d['type']['code'].to_i == 3 || d['type']['code'].to_i == 4}
	# if tempEndDate.length > 1
	# 	finalDates['end_date'] = tempEndDate.select{|d| d['type']['code'].to_i == 4}[0]['iso_date']
	# elsif tempEndDate.length == 0
	# 	finalDates['end_date'] = 'N/A'
	# else
	# 	finalDates['end_date'] = tempEndDate.first['iso_date']
	# end
  finalDates
end