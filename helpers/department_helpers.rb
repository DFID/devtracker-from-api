module DepartmentHelpers

  include CommonHelpers

  def get_department_details(deptCode)

    firstDayOfFinYear = first_day_of_financial_year(DateTime.now)
    lastDayOfFinYear = last_day_of_financial_year(DateTime.now)

  	departmentInfo = Oj.load(File.read('data/OGDs.json'))

    deptIdentifier=departmentInfo[deptCode]['identifiers']

  	activeProject = Oj.load(RestClient.get settings.oipa_api_url + "activities/?reporting_organisation="+deptIdentifier+"&hierarchy=1&format=json&fields=activity_status&page_size=250&activity_status=2")

    currentActiveProjectBudget = Oj.load(RestClient.get settings.oipa_api_url + "budgets/aggregations/?format=json&reporting_organisation="+deptIdentifier+"&budget_period_start=#{firstDayOfFinYear}&budget_period_end=#{lastDayOfFinYear}&group_by=reporting_organisation&aggregations=value&activity_status=2")

    if currentActiveProjectBudget["count"]==0 then
       totalCurrentActiveProjectBudget = 0
    else
       totalCurrentActiveProjectBudget = currentActiveProjectBudget["results"][0]["value"]  
    end   

    closedProject = Oj.load(RestClient.get settings.oipa_api_url + "activities/?reporting_organisation="+deptIdentifier+"&hierarchy=1&format=json&fields=activity_status&page_size=250&activity_status=3,4,5")

    closedProjectBudget = Oj.load(RestClient.get settings.oipa_api_url + "budgets/aggregations/?format=json&reporting_organisation="+deptIdentifier+"&group_by=reporting_organisation&aggregations=value&activity_status=3,4,5")

    countrywiseActiveProjectCount = Oj.load(RestClient.get settings.oipa_api_url + "activities/aggregations/?hierarchy=1&format=json&reporting_organisation="+deptIdentifier+"&group_by=recipient_country&aggregations=count&activity_status=2")

    deptSectorData  = Oj.load(RestClient.get settings.oipa_api_url + "budgets/aggregations/?format=json&reporting_organisation="+deptIdentifier+"&activity_status=2&group_by=sector,&aggregations=value&page_size=500")

    budgetSectorList = deptSectorData["results"].select {|sector| sector["value"].to_f!=0 }.to_a.map do |elem| 
        {
                "sectorId"               => elem["sector"]["code"],
                "higherLevelSectorName"  => "",
                "budget"                 => elem["value"].to_i
        }
      end

    budgetSectorList = get_hash_data_with_high_level_sector_name(budgetSectorList)

    sumBudgetActiveSector = budgetSectorList.group_by  { |b| b["higherLevelSectorName"]
      }.map { |higherLevelSectorName, bs|
        {
                "higherLevelSectorName"  => higherLevelSectorName,
                "budget"             => bs.inject(0) { |v, b| v + b["budget"] }
            }
        }

  	returnObject = {
            :code => deptCode,
            :name => departmentInfo[deptCode]["name"],
            :identifier => deptIdentifier,
            :description => departmentInfo[deptCode]["description"],
            :totalActiveProjectCount => activeProject["count"],
            :totalCurrentActiveProjectBudget => totalCurrentActiveProjectBudget,
            :totalCloseProjectCount => closedProject["count"],
            :totalCloseProjectBudget => closedProjectBudget["results"][0]["value"],
            :countrywiseActiveProjectCount => countrywiseActiveProjectCount["results"],
            :sumBudgetActiveSector => sumBudgetActiveSector
            }
    
  end

end
