module CountryHelpers

  # Groups all the countries by their alphabetical listing
  def country_list

    # first get all the country codes we care about
    relevant_country_codes = @cms_db['projects'].find({ 'projectType' => 'country' }, :fields => ['recipient']).to_a.map { |c| c['recipient'] }

    # first we get a list of all countries
    all_countries = @cms_db['countries'].find({'code' => { '$in' => relevant_country_codes }}).to_a

    # we convert the hash to an array and [LETTER, GROUPING] and 
    # sort it alphabetically
    all_countries.sort_by { |country| country['name'].upcase }
  end

  def dfid_total_budget
    # aggregates the budgets from all projects
    @cms_db['projects'].aggregate([{ 
      "$group" => { 
        "_id"   => nil,  
        "total" => { 
          "$sum" => "$currentFYBudget"  
        }  
      } 
    }]).first['total'].to_f
  end

  def active_projects(countryCode)
    @cms_db['projects'].find({  'projectType' => "country",
                                'recipient' => countryCode,
                                'status' => { '$lt'=> 3 }
                              }).count()
  end

  def sector_groups(countryCode) 
    sectors = @cms_db['sector-breakdowns'].find({'country' => countryCode}).sort({'total' => -1}).to_a.map { |sector|
      higher = @cms_db['sector-hierarchies'].find_one({ "sectorCode" => sector['sector'].to_i })       
      higher = higher || {
        "highLevelCode" => 0,
        "highLevelName" => "Other"
      }

      {
        "sector" => higher['highLevelCode'],
        "name"   => higher['highLevelName'],
        "total"  => sector['total']
      }
    }.select { |sector| 
        sector['sector'] != 0 
    }.group_by { |sector| 
        sector['sector']
    }.map { |sector, counts|
      {
        'sector' => sector,
        'name'   => counts.first['name'],
        'total'  => counts.map { |c| c['total'] }.inject(:+)
      }
    }.sort_by { |s| -s['total']}

    if sectors.count > 5 then
        sectors = sectors[0..4] << {
            'name'  => "Other",
            'total' => sectors[5..-1].map { |s| s['total'] }.inject(:+)
        }
    end

    total = (sectors.map { |s| s['total'] }.inject(:+) || 0) + 0.0

    sectors.each { |s| 
      s['percentage'] = format_percentage(s['total'] / total * 100) 
    }

    sectors
  end

  
  def country_project_budgets(country_code)
    projectCodes = @cms_db['projects'].find({
      "projectType" => "country", "recipient" => country_code
      }, :fields => ["iatiId"]).to_a.map{|b| b["iatiId"]}

    project_budgets = @cms_db['project-budgets'].find({
      "id" => {
        "$in" => projectCodes
      }
    }).to_a.group_by{|b| first_day_of_financial_year Date.parse(b["date"])}.map{|date, budgets|
      
      summedBudgets = budgets.reduce(0) {|memo, budget| memo + budget["value"]}
      [date, summedBudgets]

    }.sort

    # determine what range to show
      current_financial_year = first_day_of_financial_year(DateTime.now)

    # if range is 6 or less just show it
      range = if project_budgets.size < 7 then
                project_budgets
              # if the last item in the list is less than or equal to 
              # the current financial year get the last 6
              elsif project_budgets.last.first <= current_financial_year
                project_budgets.last(6)
              # other wise show current FY - 3 years and cuurent FY + 3 years
              else
                index_of_now = project_budgets.index { |i| i[0] == current_financial_year }

                if index_of_now.nil? then
                  project_budgets.last(6)
                else
                  project_budgets[[index_of_now-3,0].max..index_of_now+2]
                end
              end

              # finally convert the range into a label format
              range.each { |item| 
                item[0] = financial_year_formatter(item[0]) 
              }

  end

  def financial_year_formatter(d)

    date = if(d.kind_of?(String)) then
      Date.parse d
    else
      d
    end

    if date.month < 4
      "FY#{(date.year-1).to_s[2..3]}/#{date.year.to_s[2..3]}"
    else
      "FY#{date.year.to_s[2..3]}/#{(date.year+1).to_s[2..3]}"
    end
  end

  def financial_year 
    now = Time.new
    if(now.month < 4)
      now.year-1
    else
      now.year
    end
  end

  def top_5_countries
    @cms_db['country-stats'].aggregate([{
      "$sort" => {
        "totalBudget" => -1
      }
    },{
      "$limit" => 5
    }]).map do |totals|  
      name = @cms_db['countries'].find_one({
        'code' => totals['code']
      })['name']

      {
        'code'        => totals['code'],
        'name'        => name,
        'totalBudget' => totals['totalBudget']
      }
    end
  end

  def country_name(countryCode)
    result = @cms_db['countries'].find({
      'code' => countryCode
    })
    (result.first || { 'name' => '' })['name']
  end

end