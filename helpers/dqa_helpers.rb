module DqaHelpers

    def dqaResponse(org_string, country_region_string, sector_string)
        url = 'https://fcdo2.iati.cloud/dqa'
        regionList = []
        countryList = []
        sectorList = Oj.load(File.read('data/dqa-sector-map.json'))
        if country_region_string.match?(/\d/)
            regionList = country_region_string.split(",")
        else
            countryList = country_region_string.split(",")
        end
        puts sectorList[sector_string.to_s]
        payload_all = {
            "organisation": org_string,
            "segmentation": {
                "countries": countryList,
                "regions": regionList,
                "sectors": sectorList[sector_string.to_s]
            },
            "failed_activities": false
        }
        puts payload_all
        response = RestClient.post(url, payload_all.to_json, { content_type: :json, accept: :json })
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
        finalData['OverallRAGBreakdown'] = {}
        finalData['OverallRAGBreakdown']['Title'] = resp['total_percentages']['title_percentage']
        finalData['OverallRAGBreakdown']['Description'] = resp['total_percentages']['description_percentage']
        finalData['OverallRAGBreakdown']['StartDate'] = resp['total_percentages']['start_date_percentage']
        finalData['OverallRAGBreakdown']['EndDate'] = resp['total_percentages']['end_date_percentage']
        finalData['OverallRAGBreakdown']['Sector'] = resp['total_percentages']['sector_percentage']
        finalData['OverallRAGBreakdown']['Location'] = resp['total_percentages']['location_data_percentage']
        finalData['OverallRAGBreakdown']['ParticipatingOrg'] = resp['total_percentages']['participating_organisations_percentage']
        finalData['OverallRAGBreakdown']['BusinessCase'] = resp['total_percentages']['document_business_case_percentage']
        finalData['OverallRAGBreakdown']['LogFrame'] = resp['total_percentages']['document_logical_framework_percentage']
        finalData['OverallRAGBreakdown']['AnnualReview'] = resp['total_percentages']['document_annual_review_percentage']
        finalData['OverallRAGBreakdown']['PCR'] = resp['total_percentages']['document_project_completion_review_percentage']
        finalData['OverallRAGBreakdown']['PartnerLinks'] = resp['total_percentages']['downstream_partner_links_percentage']
        ## Calculate project pass rate
        percentageValues = resp['h2_percentages'].values
        totalSum = percentageValues.sum
        count = percentageValues.size
        finalData['ProjectPassRate'] = ((totalSum.to_f/(count*100))*100).round
        finalData['ProjectRAGBreakdown'] = {}
        finalData['ProjectRAGBreakdown']['Title'] = resp['h2_percentages']['title_percentage']
        finalData['ProjectRAGBreakdown']['Description'] = resp['h2_percentages']['description_percentage']
        finalData['ProjectRAGBreakdown']['StartDate'] = resp['h2_percentages']['start_date_percentage']
        finalData['ProjectRAGBreakdown']['EndDate'] = resp['h2_percentages']['end_date_percentage']
        finalData['ProjectRAGBreakdown']['Sector'] = resp['h2_percentages']['sector_percentage']
        finalData['ProjectRAGBreakdown']['Location'] = resp['h2_percentages']['location_percentage']
        finalData['ProjectRAGBreakdown']['ParticipatingOrg'] = resp['h2_percentages']['participating_org_percentage']
        ## Calculate programme pass rate
        percentageValues = resp['h1_percentages'].values
        totalSum = percentageValues.sum
        count = percentageValues.size
        
        finalData['ProgrammePassRate'] = ((totalSum.to_f/(count*100))*100).round
        finalData['ProgrammeRAGBreakdown'] = {}
        finalData['ProgrammeRAGBreakdown']['Title'] = resp['h1_percentages']['title_percentage']
        finalData['ProgrammeRAGBreakdown']['Description'] = resp['h1_percentages']['description_percentage']
        finalData['ProgrammeRAGBreakdown']['StartDate'] = resp['h1_percentages']['start_date_percentage']
        finalData['ProgrammeRAGBreakdown']['EndDate'] = resp['h1_percentages']['end_date_percentage']
        finalData['ProgrammeRAGBreakdown']['Sector'] = resp['h1_percentages']['sector_percentage']
        finalData['ProgrammeRAGBreakdown']['Location'] = resp['h1_percentages']['location_percentage']
        finalData['ProgrammeRAGBreakdown']['ParticipatingOrg'] = resp['h1_percentages']['participating_org_percentage']
        ## DocumentPassRate calculation
        finalData['DocumentPassRate'] = (((resp['total_percentages']['document_annual_review_percentage']+resp['total_percentages']['document_business_case_percentage']+resp['total_percentages']['document_logical_framework_percentage']+resp['total_percentages']['document_project_completion_review_percentage']).to_f/(4*100))*100).round
        finalData['TotalBudget'] = convert_numbers_to_human_readable_format(resp['summary']['total_budget'])#Money.new(resp['summary']['total_budget'].to_f*100,'GBP').format(:no_cents_if_whole => true,:sign_before_symbol => false)
        finalData['DocumentRAGBreakdown'] = {}
        finalData['DocumentRAGBreakdown']['BusinessCase'] = resp['total_percentages']['document_business_case_percentage']
        finalData['DocumentRAGBreakdown']['LogFrame'] = resp['total_percentages']['document_logical_framework_percentage']
        finalData['DocumentRAGBreakdown']['AnnualReview'] = resp['total_percentages']['document_annual_review_percentage']
        finalData['DocumentRAGBreakdown']['PCR'] = resp['total_percentages']['document_project_completion_review_percentage']
        @data = finalData
    end
end