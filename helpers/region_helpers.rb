#require "helpers/project_helpers"

module RegionHelpers

  include ProjectHelpers

  # returns an alphabetically sorted list of all regions
  def region_list

    # first get all the region codes we care about
    relevant_region_codes = @cms_db['projects'].find({ 'projectType' => 'regional' }, :fields => ['recipient']).to_a.map { |c| c['recipient'] }

    # get all regions
    all_regions = @cms_db['regions'].find({'code' => { '$in' => relevant_region_codes }})

    # sort them alphabetically (irrespective of case)
    all_regions.sort_by { |region| region['name'].upcase }
  end

  def global_list
    dfid_global_projects.select { |region| region[:budget] > 0 }.sort_by { |region| region[:region].upcase}
  end

  def get_region_projects(projects,n)
    results = {}
    sectorValuesJSON = RestClient.get settings.oipa_api_url + "activities/aggregations?format=json&group_by=sector&aggregations=count&reporting_organisation=GB-1&related_activity_recipient_region=#{n}"
    results['highLevelSectorList'] = high_level_sector_list_filter(sectorValuesJSON)
    results['project_budget_higher_bound'] = 0
    results['actualStartDate'] = '0000-00-00T00:00:00' 
    results['plannedEndDate'] = '0000-00-00T00:00:00'
    unless projects['results'][0].nil?
      results['project_budget_higher_bound'] = projects['results'][0]['activity_aggregations']['total_child_budget_value']
    end
    results['actualStartDate'] = RestClient.get settings.oipa_api_url + "activities?format=json&page_size=1&fields=activity_dates&reporting_organisation=GB-1&hierarchy=1&related_activity_recipient_region=#{n}&ordering=actual_start_date"
    results['actualStartDate'] = JSON.parse(results['actualStartDate'])
    unless results['actualStartDate']['results'][0].nil? 
      results['actualStartDate'] = results['actualStartDate']['results'][0]['activity_dates'][1]['iso_date']
    end
    results['plannedEndDate'] = RestClient.get settings.oipa_api_url + "activities?format=json&page_size=1&fields=activity_dates&reporting_organisation=GB-1&hierarchy=1&related_activity_recipient_region=#{n}&ordering=-planned_end_date"
    results['plannedEndDate'] = JSON.parse(results['plannedEndDate'])
    unless results['plannedEndDate']['results'][0].nil?
      results['plannedEndDate'] = results['plannedEndDate']['results'][0]['activity_dates'][2]['iso_date']
    end
    return results
  end
end