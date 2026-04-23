module DqaHelpers

    def dqaResponse(org_string, country_region_string, sector_string)
        url = 'https://fcdo2.iati.cloud/dqa'
        regionList = []
        countryList = []
        sectorList = []
        if country_region_string.match?(/\d/)
            regionList = country_region_string.split(",")
        else
            countryList = country_region_string.split(",")
        end
        sectorList = sector_string.split(",")
        payload_all = {
            "organisation": org_string,
            "segmentation": {
                "countries": countryList,
                "regions": regionList,
                "sectors": sectorList
            },
            "failed_activities": false
        }
        payload_programmes = {
            "organisation": org_string,
            "hierarchy": 1,
            "segmentation": {
                "countries": countryList,
                "regions": regionList,
                "sectors": sectorList
            },
            "failed_activities": false
        }
        payload_projects = {
            "organisation": org_string,
            "hierarchy": 2,
            "segmentation": {
                "countries": countryList,
                "regions": regionList,
                "sectors": sectorList
            },
            "failed_activities": false
        }
        response = RestClient.post(url, payload_all.to_json, { content_type: :json, accept: :json })
        response_programmes = RestClient.post(url, payload_programmes.to_json, { content_type: :json, accept: :json })
        response_projects = RestClient.post(url, payload_projects.to_json, { content_type: :json, accept: :json })
        # 4. Parse the JSON response into a Ruby variable (Hash)
        resp = JSON.parse(response.body)
        ##
        finalData = {}
        orgList = Oj.load(File.read('data/OGDs.json'))
        selectedOrg = orgList.find {|key, val| val["identifiers"] == org_string}
        finalData['OrganisationID'] = org_string
        finalData['OrganisationTitle'] = selectedOrg[1]['name']
        finalData['Org_ShortForm'] = selectedOrg[0].downcase
        ## Calculate overall score
        percentageValues = resp['percentages'].values
        totalSum = percentageValues.sum
        count = percentageValues.size
        finalData['OverallPassRate'] = ((totalSum.to_f/(count*100))*100).round
        finalData['ActiveProgrammeCount'] = resp['summary']['total_programmes']
        finalData['ActiveProjectCount'] = resp['summary']['total_projects']
        ## Calculate project pass rate
        resp_projects = JSON.parse(response_projects.body)
        percentageValues = resp_projects['percentages'].values
        totalSum = percentageValues.sum
        count = percentageValues.size
        finalData['ProjectPassRate'] = ((totalSum.to_f/(count*100))*100).round
        finalData['ProjectRAGBreakdown'] = {}
        finalData['ProjectRAGBreakdown']['Title'] = resp_projects['percentages']['title_percentage']
        finalData['ProjectRAGBreakdown']['Description'] = resp_projects['percentages']['description_percentage']
        finalData['ProjectRAGBreakdown']['StartDate'] = resp_projects['percentages']['start_date_percentage']
        finalData['ProjectRAGBreakdown']['EndDate'] = resp_projects['percentages']['end_date_percentage']
        finalData['ProjectRAGBreakdown']['Sector'] = resp_projects['percentages']['sector_percentage']
        finalData['ProjectRAGBreakdown']['Location'] = resp_projects['percentages']['location_data_percentage']
        finalData['ProjectRAGBreakdown']['ParticipatingOrg'] = resp_projects['percentages']['participating_organisations_percentage']
        ## Calculate programme pass rate
        resp_programmes = JSON.parse(response_programmes.body)
        percentageValues = resp_programmes['percentages'].values
        totalSum = percentageValues.sum
        count = percentageValues.size
        
        finalData['ProgrammePassRate'] = ((totalSum.to_f/(count*100))*100).round
        finalData['ProgrammeRAGBreakdown'] = {}
        finalData['ProgrammeRAGBreakdown']['Title'] = resp_programmes['percentages']['title_percentage']
        finalData['ProgrammeRAGBreakdown']['Description'] = resp_programmes['percentages']['description_percentage']
        finalData['ProgrammeRAGBreakdown']['StartDate'] = resp_programmes['percentages']['start_date_percentage']
        finalData['ProgrammeRAGBreakdown']['EndDate'] = resp_programmes['percentages']['end_date_percentage']
        finalData['ProgrammeRAGBreakdown']['Sector'] = resp_programmes['percentages']['sector_percentage']
        finalData['ProgrammeRAGBreakdown']['Location'] = resp_programmes['percentages']['location_data_percentage']
        finalData['ProgrammeRAGBreakdown']['ParticipatingOrg'] = resp_programmes['percentages']['participating_organisations_percentage']
        ## DocumentPassRate calculation
        finalData['DocumentPassRate'] = (((resp['percentages']['document_annual_review_percentage']+resp['percentages']['document_business_case_percentage']+resp['percentages']['document_logical_framework_percentage']+resp['percentages']['document_project_completion_review_percentage']).to_f/(4*100))*100).round
        finalData['TotalBudget'] = convert_numbers_to_human_readable_format(resp['summary']['total_budget'])#Money.new(resp['summary']['total_budget'].to_f*100,'GBP').format(:no_cents_if_whole => true,:sign_before_symbol => false)
        finalData['DocumentRAGBreakdown'] = {}
        finalData['DocumentRAGBreakdown']['BusinessCase'] = resp['percentages']['document_business_case_percentage']
        finalData['DocumentRAGBreakdown']['LogFrame'] = resp['percentages']['document_logical_framework_percentage']
        finalData['DocumentRAGBreakdown']['AnnualReview'] = resp['percentages']['document_annual_review_percentage']
        puts finalData
        @data = finalData
    end
end