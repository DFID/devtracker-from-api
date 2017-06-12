module OGDHelper

=begin

Author: Auninda Rumy Saleque

Method Name: generate_ogd_data

Purpose: This method returns the data necessary for populating the other government department pages.

Input:
ogdCode - The reporting org id whose related activities will be returned

Outputs:
Returns a Hash 'ogdData' with the following keys:

- project_budget_higher_bound (String)	-	This is the value that helps set the maximum budget value needed for the left hand side budget slider filter.

- projects (Hash)						-	This is a hash storing the projects list data relevant to the reporting organisation

- project_count (String)				-	This is the number of projects returned based on the reporting organisation

- highLevelSectorList (Hash)			-	This returns the sectors list data for the left hand side sectors filter

- actualStartDate (ISO Date)			-	This returns the actual start date for the returned project list which is needed to set the 
											starting bound of the left hand side date range slider filter.

- plannedEndDate (ISO Date)				-	This returns the planned end date for the returned project list which is needed to set the 
											ending bound of the left hand side date range slider filter.
=end

	def get_ogd_all_projects_data(ogdCode)
    allProjectsData = {}
    allProjectsData['countryAllProjectFilters'] = get_static_filter_list()

    oipa_project_list = RestClient.get settings.oipa_api_url + "activities/?hierarchy=1&format=json&reporting_organisation=#{ogdCode}&page_size=10&fields=descriptions,activity_status,iati_identifier,url,title,reporting_organisations,activity_plus_child_aggregation,aggregations&activity_status=2&ordering=-activity_plus_child_budget_value"
    allProjectsData['projects']= JSON.parse(oipa_project_list)
    sectorValuesJSON = RestClient.get settings.oipa_api_url + "activities/aggregations/?format=json&group_by=sector&aggregations=count&reporting_organisation=#{ogdCode}&activity_status=2"
    allProjectsData['highLevelSectorList'] = high_level_sector_list_filter(sectorValuesJSON)

    allProjectsData['project_budget_higher_bound'] = 0
    allProjectsData['actualStartDate'] = '1990-01-01T00:00:00' 
    allProjectsData['plannedEndDate'] = '2000-01-01T00:00:00'
    unless allProjectsData['projects']['results'][0].nil? || allProjectsData['projects']['results'][0]['aggregations']['activity_children'].nil?
      allProjectsData['project_budget_higher_bound'] = allProjectsData['projects']['results'][0]['aggregations']['activity_children']['budget_value']
    end
    allProjectsData['actualStartDate'] = RestClient.get settings.oipa_api_url + "activities?format=json&page_size=1&fields=activity_dates&reporting_organisation=#{ogdCode}&hierarchy=1&ordering=actual_start_date&start_date_gte=1900-01-02&activity_status=2"
    allProjectsData['actualStartDate'] = JSON.parse(allProjectsData['actualStartDate'])
    if(allProjectsData['actualStartDate']['count'] > 0)
		tempStartDate = allProjectsData['actualStartDate']['results'][0]['activity_dates'].select{|activityDate| activityDate['type']['code'] == '2'}.first
		if (tempStartDate.nil?)
			tempStartDate = allProjectsData['actualStartDate']['results'][0]['activity_dates'].select{|activityDate| activityDate['type']['code'] == '1'}.first
		end
    	allProjectsData['actualStartDate'] = tempStartDate
    	allProjectsData['actualStartDate'] = allProjectsData['actualStartDate']['iso_date']
    else
    	allProjectsData['actualStartDate'] = '1990-01-01T00:00:00'
    end

    allProjectsData['plannedEndDate'] = RestClient.get settings.oipa_api_url + "activities?format=json&page_size=1&fields=activity_dates&reporting_organisation=#{ogdCode}&hierarchy=1&ordering=-planned_end_date&end_date_isnull=False&activity_status=2"
    allProjectsData['plannedEndDate'] = JSON.parse(allProjectsData['plannedEndDate'])
    if(allProjectsData['plannedEndDate']['count'] > 0)
		tempEndDate = allProjectsData['plannedEndDate']['results'][0]['activity_dates'].select{|activityDate| activityDate['type']['code'] == '3'}.first
		if (tempEndDate.nil?)
			tempEndDate = allProjectsData['plannedEndDate']['results'][0]['activity_dates'].select{|activityDate| activityDate['type']['code'] == '4'}.first
		end
    	allProjectsData['plannedEndDate'] = tempEndDate
    	allProjectsData['plannedEndDate'] = allProjectsData['plannedEndDate']['iso_date']
    else
    	allProjectsData['plannedEndDate'] = '2100-01-01T00:00:00'
    end

    oipa_document_type_list = RestClient.get settings.oipa_api_url + "activities/aggregations/?format=json&group_by=document_link_category&aggregations=count&reporting_organisation=#{ogdCode}&activity_status=2"
    document_type_list = JSON.parse(oipa_document_type_list)
    allProjectsData['document_types'] = document_type_list['results']

    #Implementing org type filters
    participatingOrgInfo = JSON.parse(File.read('data/participatingOrgList.json'))
    oipa_implementingOrg_type_list = RestClient.get settings.oipa_api_url + "activities/aggregations/?format=json&group_by=participating_organisation&aggregations=count&reporting_organisation=#{ogdCode}&hierarchy=1&activity_status=2"
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

end