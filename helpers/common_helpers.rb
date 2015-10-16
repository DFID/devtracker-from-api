module CommonHelpers

	#New One based on API Call
  def financial_year_wise_budgets(yearWiseBudgets,type)

    projectBudgets = []
    
    yearWiseBudgets.each do |y|
      if y["quarter"]==1
          p=[y["quarter"],y["budget"],y["year"],y["year"]-1]
      else
          p=[y["quarter"],y["budget"],y["year"],y["year"]]
      end
      
      projectBudgets << p        
    end

    #project_budgets
    #project_budgets = year_wise_budgets.group_by{|b| b["year"]}.map{|year, budgets|
        #summedBudgets = budgets.reduce(0) {|memo, budget| memo + budget["budget"]}
        #[year, summedBudgets]
        #}.sort
     
     finYearWiseBudgets = projectBudgets.group_by{|b| b[3]}.map{|year, budgets|
        summedBudgets = budgets.reduce(0) {|memo, budget| memo + budget[1]}
        [year, summedBudgets]
        }.sort   

    # determine what range to show
      #current_financial_year = first_day_of_financial_year(DateTime.now)
      currentFinancialYear = financial_year

    # if range is 6 or less just show it
    if (type=="C") then
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
              tempFYear = ""
              tempFYAmount = ""
              finalData = []
              # finally convert the range into a label format
              range.each { |item| 
                item[0] = financial_year_formatter(item[0])
                tempFYear  = tempFYear + "'" + item[0] + "'" + ","
                tempFYAmount = tempFYAmount + "'" + item[1].to_s + "'" + ","
              }
              finalData[0] = tempFYear
              finalData[1] = tempFYAmount
              return finalData

    elsif (type=="P") then
    	finYearWiseBudgets.each { |item| 
          item[0] = financial_year_formatter(item[0]) 
        }
              	          
    end

  end

  #New One based on API Call
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

end
