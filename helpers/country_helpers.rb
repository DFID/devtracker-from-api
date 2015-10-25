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
end