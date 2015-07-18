require "helpers/codelists"
require "helpers/lookups"

module ProjectHelpers

    
    include CodeLists

    def dfid_total_projects_budget(projectType)
        # aggregates a total budget of all the dfid projects for a given type (global, coutry, regional)
        (dfid_projects_budget(projectType).first || { 'total' => 0 })['total']
    end

    def dfid_projects_budget(projectType)
        @cms_db['projects'].aggregate([{
            "$group" => {
                "_id"   => "$projectType",
                "total" => {
                    "$sum" => "$currentFYBudget"
                }
            } }, {
                "$match" => {
                    "_id" => projectType
                }
            }]
        )
    end

    def is_dfid_project(projectCode)   
        projectCode[0, 4] == "GB-1"
    end

    def dfid_region_projects_budget(regionCode)
        # aggregates a total budget of all the regional projects for the given region code
        result = @cms_db['projects'].aggregate([{
            "$match" => {
                "projectType" => "regional",
                "recipient" => regionCode
                }
            }, {
                "$group" => {
                    "_id" => "$recipient",
                    "total" => {
                        "$sum" => "$currentFYBudget"
                    }
                }
            }]
        )
        (result.first || { 'total' => 0 })['total']
    end

    def dfid_country_projects_data
        result = @cms_db['projects'].aggregate([{
                "$match" => {
                    "projectType" => "country",
                    "status" => {
                        "$lt" => 3
                    }
                }
            }, {
                "$group" => { 
                    "_id" => "$recipient", 
                    "total" => {
                        "$sum" => "$currentFYBudget"
                    }
                }
            }, {
                "$sort" => {
                    "_id" => -1
                }
            }]
        )
        result.map { |country| {
            country['_id'] => {
                :country  =>  (@cms_db['countries'].find({ "code" => country['_id'] }).first || { 'name' => '' })['name'],
                :id       => country['_id'],
                :projects => @cms_db['projects'].find({ "recipient" => country['_id'], "projectType" => "country"}).count(),
                :budget   => (@cms_db['country-stats'].find({"code" => country['_id']}).first || { 'totalBudget' => 0 })['totalBudget'],
                :flag     => '/images/flags/' + country['_id'].downcase + '.png'
            }
        }}.inject({}) { |obj, entry| 
            obj.merge! entry
        }.to_json
    end

    def dfid_regional_projects_data
        # aggregates budgets of the dfid regional projects grouping them by regions
        @cms_db['regions'].find().map { |region| {
            :region => region['name'],
            :code   => region['code'],
            :budget => dfid_region_projects_budget(region['code']) || 0
        }}.to_json
    end

    def dfid_global_projects
        @@global_recipients.map { |code, name|
            {
                :code   => code,
                :region => name,
                :budget => (@cms_db['projects'].aggregate([{
                    "$match" => {
                        'projectType' => 'global',
                        'recipient'   => code
                    },
                }, {
                    "$group" => {
                        "_id" => nil,
                        "total" => { "$sum" => "$currentFYBudget" }
                    }
                }]).first || {"total" => 0})["total"]
            }
        }
    end

    def dfid_global_projects_data
        dfid_global_projects.to_json
    end

    def choose_better_date(actual, planned)
        # determines project actual start/end date - use actual date, planned date as a fallback
        unless actual.nil? || actual == ''
            return (Time.at(actual).to_f * 1000.0).to_i
        end

        unless planned.nil? || planned == ''
            return (Time.at(planned).to_f * 1000.0).to_i
        end

        return 0
    end

    def project_budgets(projectId)
        project_budgets = @cms_db['project-budgets'].find({
              'id' => projectId
            }).to_a
        graph = []
        graph + project_budgets.inject({}) { |results, budget| 
          fy = financial_year_formatter budget['date']
          results[fy] = (results[fy] || 0) + budget['value']
          results
        }.map { |fy, budget| [fy, budget] }.inject({}) { |graph, group|
          graph[group.first] = (graph[group.first] || 0) + group.last
          graph
        }.map { |fy, budget| [fy, budget] }.sort
    end

    def project_budget_per_fy(projectId)
        # project all budgets into a suitable format
        budgets = coerce_budget_vs_spend_items(
            @cms_db['project-budgets'].find(
                { "id" => projectId }, :sort => ['date', Mongo::DESCENDING]
            ), "budget"
        )

        # project all spends into a suitable format
        spends = coerce_budget_vs_spend_items(
            @cms_db['transactions'].find({
                "project" => projectId,
                'type'    => {
                    '$in' => ['D', 'E']
                }
            }), "spend"
        )

        # merge the series and sort by financial year
        series = (spends + budgets).group_by { |item|
            item['fy']
        }.map { |fy, items|
            # So we coerce this into a partially projected list of pairs
            [
                fy,
                (items.find { |b| b['type'] == 'budget' } || {'value' => 0})['value'],
                (items.find { |b| b['type'] == 'spend' } || {'value' => 0})['value']
            ]
        }.sort_by { |item| item.first }

        # determine what range to show
        current_financial_year = first_day_of_financial_year(DateTime.now)

        # if range is 6 or less just show it
        range = if series.size < 7 then
          series
        # if the last item in the list is less than or equal to 
        # the current financial year get the last 6
        elsif series.last.first <= current_financial_year
          series.last(6)
        # other wise show current FY - 3 years and cuurent FY + 3 years
        else
          index_of_now = series.index { |i| i[0] == current_financial_year }

          if index_of_now.nil? then
            series.last(6)
          else
            series[[index_of_now-3,0].max..index_of_now+2]
          end
        end

        # finally convert the range into a label format
        range.each { |item| 
          item[0] = financial_year_formatter(item[0]) 
        }

        range
    end

    def total_project_budget(projectId)
        # aggregates and sums the budgets for a given project
        result = @cms_db['project-budgets'].aggregate([{
                "$match" => {
                    "id" => projectId
                }
            }, {
                "$group" => { 
                    "_id" => nil,
                    "total" => {
                        "$sum" => "$value"
                    }
                }
            }]
        )

        if result.size > 0 then
            result.first['total']
        else 
            0
        end


    end

    def project_sector_groups(projectId)        
        sectorGroups = @cms_db['project-sector-budgets'].find({
            "projectIatiId" => projectId
        }).map { |s| {
            "name"   => s['sectorName'] || sector(s['sectorCode']),
            "code"   => s['sectorCode'],
            "budget" => s['sectorBudget']
        }}
        if sectorGroups.any? then
            sectorGroups = sectorGroups.group_by { |s| 
                s['code'] }.map do |code, sectors| { 
                "code" => code, "name" => sectors[0]["name"], "budget" => sectors.map { |sec| sec["budget"] }.inject(:+)
            } end.sort_by{ |sg| -sg["budget"]}
            sectorsTotalBudget = Float(sectorGroups.map {|s| s["budget"]}.inject(:+))

            sectorGroups.map { |sg| {
                :sector => sg['name'],
                :budget => sg['budget'] / sectorsTotalBudget * 100.0,
                :formatted => format_percentage(sg['budget'] / sectorsTotalBudget * 100)
            }}
        else
            return sectorGroups
        end
    end

    def transaction_description(transaction, transactionType)
        if(transactionType == "C")
            transaction['title'] || ""
        elsif(transactionType == "IF")
            transaction_title(transactionType)
        else
            transaction['description']
        end
    end

    def associated_country(projectCode)
        country = @cms_db['countries'].find_one({'code' => projectCode}) || {"name" => ""} 
        country['name']
    end

    def project_documents(projectCode)
        @cms_db['documents'].find({ 'project' => projectCode}).count
    end

private

    def first_day_of_financial_year(date_value)
        if date_value.month > 3 then
            Date.new(date_value.year, 4, 1)
        else
            Date.new(date_value.year - 1, 4, 1)
        end
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

end
