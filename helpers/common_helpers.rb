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
          fy =  if  b["quarter"]==1 then
                    b["year"]-1
                else
                    b["year"]
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

end
