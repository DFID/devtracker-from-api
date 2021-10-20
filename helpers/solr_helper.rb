module SolrHelper

    ## Filter handling driver goes below ##
    def filterDriver(filter, apiUrl, mappingFileUrl)
        finalData = []
        case filter
        ## ADDING A NEW FILTER ##
        # Main logic is to prepare an array of key/val pairs which will work as the DevTracker left hand side filter checkbox titles and values.
        # Also make sure before adding a new filter preparation here, you have updated the solr-config.json file with the new filter information
        # taken from the IATI standard's fields list. All the fiter related information comes from the json config file.
        # when 'iati_field_id_for_this_filter_goes_here'
        # Get the facet list from the solr end point
        # response = Oj.load(RestClient.get api_simple_log(apiUrl))
        # store the returned response in a variable. Example below
        # activityStatusCodes  = response['facet_counts']['facet_fields'][filter]
        # Load any mapped file information if available. This file's data will be used as the filter checkbox titles. If nothing present, then use the keys as values
        # iterate over each item from the returned facets
        # match that item against your mapped file data for getting the checkbox title as mentioned previously.
        # push the key, value pair to the finalData array
        # Sort the finalData array according to it's keys.
        # Return the finalData array.
        # This will feed the main view page with necessary key/value pairs for the target filter
        # Please look at the activity_status_code filter to get a clear understanding of how you can add a new filter quickly

        # Activity Status Code filter. 
        # The 'activity_status_code' filter is a supported IATI standard field which is indexed by the iati.cloud solr engine. 
        when 'activity_status_code'
            puts apiUrl
            response = Oj.load(RestClient.get api_simple_log(apiUrl))
            activityStatusCodes  = response['facet_counts']['facet_fields'][filter]
            statusCodeDetails = Oj.load(File.read(mappingFileUrl))
            activityStatusCodes.each_with_index do |value, index|
                # The reason we did a check of this is because, solr engine returns a flat array 
                # with first position holding the facet data and the second position holding data count.
                # Right now, we are not working with the data count. Hence, that field data is not handled. Only the even positions are being taken care of.
                if index.even?
                    tempStatus = statusCodeDetails.select{|status| status['code'].include? value.to_i}.first
                    if finalData.detect{|data| data['key'].to_s == tempStatus['name']}.nil?
                        finalData.push(populateKeyVal(tempStatus['name'], tempStatus['code'].join(' OR ')))
                    end
                end
            end
            # Sort Datac
            finalData = finalData.sort_by {|data| data['key']}
        when 'sector_code'
            # Write logic for this filter that will prepare the key value pairs
            response = Oj.load(RestClient.get api_simple_log(apiUrl))
            sectorValues  = response['facet_counts']['facet_fields'][filter]
            highLevelSector = Oj.load(File.read('data/sectorHierarchies.json'))
            highLevelSectorHash = {}

            sectorValues.each_with_index do |value, index|
                if index.even?
                    highLevelSector.find do |source|
                        if source["Code (L3)"].to_s == value
                            if !highLevelSectorHash.has_key?(source["High Level Sector Description"].to_s)
                                highLevelSectorHash[source["High Level Sector Description"].to_s] = {}
                                if highLevelSectorHash[source["High Level Sector Description"].to_s].length > 0
                                    highLevelSectorHash[source["High Level Sector Description"].to_s][0] = " OR " + value.to_s
                                else
                                    highLevelSectorHash[source["High Level Sector Description"].to_s][0] = value.to_s
                                end
                            else
                                if highLevelSectorHash[source["High Level Sector Description"].to_s].length > 0
                                    highLevelSectorHash[source["High Level Sector Description"].to_s][0].concat(" OR " + value.to_s);
                                else
                                    highLevelSectorHash[source["High Level Sector Description"].to_s][0].concat(value.to_s);
                                end
                            end
                        end
                    end
                end
            end
            # Populate the key/value pairs for the target filter in the finalData array. This array will be same for any new filters you want to add. 
            # Main data preparation logic has to go in the above section.
            highLevelSectorHash.each do |key, val|
                finalData.push(populateKeyVal(key, val[0]))
            end
            # Sort data alphabetically according to the keys
            finalData = finalData.sort_by {|data| data['key']}
        when 'participating_org_ref'
            response = Oj.load(RestClient.get api_simple_log(apiUrl))
            participatingOrgList = Oj.load(File.read('data/participating-orgs/processed_orgList.json'))
            implementingOrgs  = response['facet_counts']['facet_fields'][filter]
            puts implementingOrgs
            implementingOrgs.each_with_index do |value, index|
                # The reason we did a check of this is because, solr engine returns a flat array 
                # with first position holding the facet data and the second position holding data count.
                # Right now, we are not working with the data count. Hence, that field data is not handled. Only the even positions are being taken care of.
                if index.even?
                    if(participatingOrgList.key?(value.capitalize()))
                        begin
                            finalData.push(populateKeyVal(participatingOrgList[value.capitalize()][0]['text'], value))    
                        rescue
                            finalData.push(populateKeyVal('No Title', value))
                        end    
                    end
                end
            end
            # Sort Data
            finalData = finalData.sort_by {|data| data['key']}
        when 'tag_code'
            response = Oj.load(RestClient.get api_simple_log(apiUrl))
            tags = response['facet_counts']['facet_fields'][filter]
            mappedTags = Oj.load(File.read(mappingFileUrl))['data']
            tags.each_with_index do |value, index|
                if index.even?
                    if(!mappedTags.find{|tag| tag['Code'] == value}.nil?)
                        finalData.push(populateKeyVal(mappedTags.find{|tag| tag['Code'] == value}['Name'], value))
                    end
                end
            end
            # Sort Data
            finalData = finalData.sort_by {|data| data['key']}
        when 'document_link_category_code'
            response = Oj.load(RestClient.get api_simple_log(apiUrl))
            docCats = response['facet_counts']['facet_fields'][filter]
            mappedDocCats = Oj.load(File.read(mappingFileUrl))['data']
            docCats.each_with_index do |value, index|
                if index.even?
                    if(!mappedDocCats.find{|doc| doc['code'] == value.to_s}.nil?)
                        finalData.push(populateKeyVal(mappedDocCats.find{|doc| doc['code'] == value.to_s}['name'], value))
                    end
                end
            end
            finalData = finalData.sort_by {|data| data['key']}
        when 'recipient_country_code'
            response = Oj.load(RestClient.get api_simple_log(apiUrl))
            countries = response['facet_counts']['facet_fields'][filter]
            mappedCountries = Oj.load(File.read(mappingFileUrl))
            countriesInfo = JSON.parse(File.read('data/countries.json'))
            countries.each_with_index do |value, index|
                if index.even?
                    if(mappedCountries.has_key?(value))
                        selectedCountry = countriesInfo.select {|country| country['code'] == value}.first
                        if selectedCountry
                            finalData.push(populateKeyVal(selectedCountry['name'], value))
                        else
                            finalData.push(populateKeyVal(mappedCountries[value], value))
                        end
                    end
                end
            end
            finalData = finalData.sort_by {|data| data['key']}
        when 'recipient_region_name'
            response = Oj.load(RestClient.get api_simple_log(apiUrl))
            regions = response['facet_counts']['facet_fields'][filter]
            regions.each_with_index do |value, index|
                if index.even?
                    finalData.push(populateKeyVal(value, value))
                end
            end
            finalData = finalData.sort_by {|data| data['key']}
        else
            finalData
        end
    end

    def populateKeyVal(key, val)
        tempHash = {}
        tempHash['key'] = key
        tempHash['value'] = val
        tempHash
    end

    def prepareFilters(query, queryType)
        solrConfig = Oj.load(File.read('data/solr-config.json'))
        apiLink = solrConfig['APILink']
        filters = solrConfig['Filters']
        mainQueryString = prepareQuery(query, queryType)
        finalFilterList = {}
        filters.each do |filter|
            finalFilterList[filter['field']] = []
            finalFilterList[filter['field']] = filterDriver(filter['field'], apiLink + filter['url'] + mainQueryString, filter['mappingFile'])
        end
        finalFilterList
    end
    ## Prepare search results ##
    def solrResponse(query, filters, queryType, startPage, dateRange, sortType)
        solrConfig = Oj.load(File.read('data/solr-config.json'))
        apiLink = solrConfig['APILink']
        mainQueryString = prepareQuery(query, queryType)
        if(dateRange != '')
            mainQueryString = mainQueryString + dateRange
        end
        # First we are going to handle the free text search under DevTracker. We are denoting this type of search with letter 'F'
        if(queryType == 'F')
            queryCategory = solrConfig['QueryCategories'][queryType]
            # Handling of filters
            # TO-DO
            preparedFilters = filters # For now, it's empty
            mainQueryString = mainQueryString + preparedFilters
            if(sortType != '')
                mainQueryString = mainQueryString + '&sort=' + sortType
            end
            # Get response based on the API responses
            puts ('---xxxx----')
            puts apiLink + queryCategory['url'] + mainQueryString +'&rows='+solrConfig['PageSize'].to_s+'&fl='+solrConfig['DefaultFieldsToReturn']+'&start='+startPage.to_s
            response = Oj.load(RestClient.get api_simple_log(apiLink + queryCategory['url'] + mainQueryString +'&rows='+solrConfig['PageSize'].to_s+'&fl='+solrConfig['DefaultFieldsToReturn']+'&start='+startPage.to_s))
            response['response']
        elsif(queryType == 'R')
            queryCategory = solrConfig['QueryCategories'][queryType]
            preparedFilters = filters
            mainQueryString = mainQueryString + ' AND reporting_org_ref:(' + settings.goverment_department_ids.gsub(","," OR ") + ')' + preparedFilters
            puts (apiLink + queryCategory['url'] + mainQueryString +'&rows='+solrConfig['PageSize'].to_s+'&fl='+solrConfig['DefaultFieldsToReturn']+'&start='+startPage.to_s)
            if(sortType != '')
                mainQueryString = mainQueryString + '&sort=' + sortType
            end
            response = Oj.load(RestClient.get api_simple_log(apiLink + queryCategory['url'] + mainQueryString +'&rows='+solrConfig['PageSize'].to_s+'&fl='+solrConfig['DefaultFieldsToReturn']+'&start='+startPage.to_s))
            response['response']
        elsif(queryType == 'C')
            queryCategory = solrConfig['QueryCategories'][queryType]
            preparedFilters = filters
            mainQueryString = mainQueryString + ' AND reporting_org_ref:(' + settings.goverment_department_ids.gsub(","," OR ") + ')' + preparedFilters
            if(sortType != '')
                mainQueryString = mainQueryString + '&sort=' + sortType
            end
            puts (apiLink + queryCategory['url'] + mainQueryString +'&rows='+solrConfig['PageSize'].to_s+'&fl='+solrConfig['DefaultFieldsToReturn']+'&start='+startPage.to_s)
            response = Oj.load(RestClient.get api_simple_log(apiLink + queryCategory['url'] + mainQueryString +'&rows='+solrConfig['PageSize'].to_s+'&fl='+solrConfig['DefaultFieldsToReturn']+'&start='+startPage.to_s))
            response['response']
        elsif(queryType == 'S')
            queryCategory = solrConfig['QueryCategories'][queryType]
            preparedFilters = filters
            mainQueryString = mainQueryString + ' AND reporting_org_ref:(' + settings.goverment_department_ids.gsub(","," OR ") + ')' + preparedFilters
            if(sortType != '')
                mainQueryString = mainQueryString + '&sort=' + sortType
            end
            puts (apiLink + queryCategory['url'] + mainQueryString +'&rows='+solrConfig['PageSize'].to_s+'&fl='+solrConfig['DefaultFieldsToReturn']+'&start='+startPage.to_s)
            response = Oj.load(RestClient.get api_simple_log(apiLink + queryCategory['url'] + mainQueryString +'&rows='+solrConfig['PageSize'].to_s+'&fl='+solrConfig['DefaultFieldsToReturn']+'&start='+startPage.to_s))
            response['response']
        elsif(queryType == 'O')
            queryCategory = solrConfig['QueryCategories'][queryType]
            preparedFilters = filters
            mainQueryString = mainQueryString + ' ' + preparedFilters
            if(sortType != '')
                mainQueryString = mainQueryString + '&sort=' + sortType
            end
            puts (apiLink + queryCategory['url'] + mainQueryString +'&rows='+solrConfig['PageSize'].to_s+'&fl='+solrConfig['DefaultFieldsToReturn']+'&start='+startPage.to_s)
            response = Oj.load(RestClient.get api_simple_log(apiLink + queryCategory['url'] + mainQueryString +'&rows='+solrConfig['PageSize'].to_s+'&fl='+solrConfig['DefaultFieldsToReturn']+'&start='+startPage.to_s))
            response['response']
        end
    end

    ## Method for preparing main search query
    def prepareQuery(query, queryType)
        solrConfig = Oj.load(File.read('data/solr-config.json'))
        mainQueryString = checkSearchTagPresence(query)
        if(mainQueryString == '')
            mainQueryString = ' ('
            if(queryType == 'F')
                queryCategory = solrConfig['QueryCategories'][queryType]
                if(queryCategory['fieldDependency'] == '')
                    solrConfig['DefaultFieldsToSearch'].each_with_index do |fieldToBeSearched, index|
                        if (solrConfig['DefaultFieldsToSearch'].length - 1 == index)
                            mainQueryString = mainQueryString + fieldToBeSearched + ':' + query.to_s + ''
                        else
                            mainQueryString = mainQueryString + fieldToBeSearched + ':' + query.to_s + ' OR '
                        end
                    end
                    mainQueryString = mainQueryString + ')'
                end
            elsif(queryType == 'R')
                queryCategory = solrConfig['QueryCategories'][queryType]
                if(queryCategory['fieldDependency'] != '')
                    mainQueryString = queryCategory['fieldDependency'] + ':' + query.to_s
                end
            elsif(queryType == 'C')
                queryCategory = solrConfig['QueryCategories'][queryType]
                if(queryCategory['fieldDependency'] != '')
                    mainQueryString = queryCategory['fieldDependency'] + ':' + query.to_s
                end
            elsif(queryType == 'O')
                queryCategory = solrConfig['QueryCategories'][queryType]
                if(queryCategory['fieldDependency'] != '')
                    mainQueryString = queryCategory['fieldDependency'] + ':' + query.to_s
                end
            elsif(queryType == 'S')
                queryCategory = solrConfig['QueryCategories'][queryType]
                if(queryCategory['fieldDependency'] != '')
                    mainQueryString = queryCategory['fieldDependency'] + ':' + query.to_s
                end
            end
            if(solrConfig["Exclusions"]["terms"].length > 0)
                mainQueryString = mainQueryString + " AND "
                solrConfig['Exclusions']['fields'].each_with_index do |fieldToBeChecked, index|
                    if (solrConfig['Exclusions']['fields'].length - 1 == index)
                        mainQueryString = mainQueryString + '!' + fieldToBeChecked + ':' + '('
                        solrConfig['Exclusions']['terms'].each_with_index do |term, index|
                            if (solrConfig['Exclusions']['terms'].length - 1 == index)
                                mainQueryString = mainQueryString + '"' + term + '"'
                            else
                                mainQueryString = mainQueryString + '"' + term + '" OR '
                            end
                        end
                        mainQueryString = mainQueryString + ")"
                    else
                        mainQueryString = mainQueryString + '!' + fieldToBeChecked + ':' + '('
                        solrConfig['Exclusions']['terms'].each_with_index do |term, index|
                            if (solrConfig['Exclusions']['terms'].length - 1 == index)
                                mainQueryString = mainQueryString + '"' + term + '"'
                            else
                                mainQueryString = mainQueryString + '"' + term + '" OR '
                            end
                        end
                        mainQueryString = mainQueryString + ") AND "
                    end
                end
            end
        end
        puts(mainQueryString)
        mainQueryString
    end

    def checkSearchTagPresence(query)
        solrConfig = Oj.load(File.read('data/solr-config.json'))
        searchTags = solrConfig['SearchTags']
        trimmedSearchedTerm = ''
        searchTags.each do |key, value|
            if(query.to_s.downcase.start_with?(key+':'))
                return trimmedSearchedTerm = value + ':(' + query.to_s.partition(key+':')[2].lstrip + ')'
            end
        end
        trimmedSearchedTerm
    end

    def addTotalBudgetWithCurrency(response)
        response['docs'].each do |r|
            r['totalBudgetWithCurrency'] = Money.new(r['activity_plus_child_aggregation_budget_value'].to_f*100, 
                                        if r['activity_plus_child_aggregation_budget_currency'].to_s == 'None'  
                                            if r['activity_plus_child_aggregation_incoming_funds_currency'].to_s == 'None'
                                                if r['activity_plus_child_aggregation_expenditure_currency'].to_s == 'None'
                                                    r['default_currency']
                                                else
                                                    r['activity_plus_child_aggregation_expenditure_currency']
                                                end
                                            else
                                                r['activity_plus_child_aggregation_incoming_funds_currency']
                                            end
                                        else r['activity_plus_child_aggregation_budget_currency'] 
                                        end
                                            ).round.format(:no_cents_if_whole => true,:sign_before_symbol => false)
        end
        response
    end
end