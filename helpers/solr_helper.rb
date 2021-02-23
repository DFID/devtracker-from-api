module SolrHelper

    ## Filter handling driver goes below ##
    def filterDriver(filter, apiUrl)
        case filter
        when 'sector_code'
            # Write logic for this filter that will prepare the key value pairs
            response = Oj.load(RestClient.get api_simple_log(apiUrl))
            sectorValues  = response['facet_counts']['facet_fields']['sector_code']
            highLevelSector = Oj.load(File.read('data/sectorHierarchies.json'))
            finalData = []
            highLevelSectorHash = {}

            sectorValues.each_with_index do |value, index|
                if index == 0 || index.even?
                    highLevelSector.find do |source|
                        if source["Code (L3)"].to_s == value
                            if !highLevelSectorHash.has_key?(source["High Level Sector Description"].to_s)
                                highLevelSectorHash[source["High Level Sector Description"].to_s] = {}
                                highLevelSectorHash[source["High Level Sector Description"].to_s][0] = value.to_s + " OR "
                            else
                                highLevelSectorHash[source["High Level Sector Description"].to_s][0].concat(value.to_s + " OR ");
                            end
                        end
                    end
                end
            end
            # Populate the key/value pairs for the target filter in the finalData array. This array will be same for any new filters you want to add. 
            # Main data preparation logic has to go in the above section.
            highLevelSectorHash.each do |key, val|
                tempHash = {}
                tempHash['key'] = key
                tempHash['value'] = val[0]
                finalData.push(tempHash)
            end
            # Sort data alphabetically according to the keys
            finalData = finalData.sort_by {|data| data['key']}
        else
            finalData = []
        end
    end

    def prepareFilters(query)
        solrConfig = Oj.load(File.read('data/solr-config.json'))
        apiLink = solrConfig['APILink']
        filters = solrConfig['Filters']
        finalFilterList = {}
        filters.each do |filter|
            finalFilterList[filter['field']] = []
            finalFilterList[filter['field']] = filterDriver(filter['field'], apiLink + filter['url'] + '&' + query)
        end
        finalFilterList
    end
    ## Prepare search results ##
    def solrResponse(query, filters, queryType, startPage)
        solrConfig = Oj.load(File.read('data/solr-config.json'))
        apiLink = solrConfig['APILink']
        # First we are going to handle the free text search under DevTracker. We are denoting this type of search with letter 'F'
        if(queryType == 'F')
            queryCategory = solrConfig['QueryCategories'][queryType]
            # Handing of filters
            # TO-DO
            preparedFilters = '' # For now, it's empty
            if(queryCategory['fieldDependency'] == '')
                mainQueryString = '&q=' + query.to_s
            end
            # Get response based on the API responses
            response = Oj.load(RestClient.get api_simple_log(apiLink + queryCategory['url'] + mainQueryString +'&rows='+solrConfig['searchLimit'].to_s+'&fl='+solrConfig['DefaultFields']+'&start='+startPage.to_s+'&'+preparedFilters))
            response['response']
        end
    end
end