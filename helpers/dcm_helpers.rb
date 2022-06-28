module DCMHelper

    include CommonHelpers

    ######## DCM TREE BUILDER LOGIC ##########
    #     when an activity id is given, do the following:
    #     0. Create a hash of object tree where keys will be the parent activity
    #     1. extract all the related activities of this activity
    #     2. create an or statement using all the activities
    #     3. generate a list of donor organisations/activities for the above list
    #     4. generate a list of receiver orgs/activities for the above list
    #     5. enter each new activity id in the hash created in the beginning.
    #     6. populate parent activity to have the child activities
    #     7. run the same mathod against each found new activity from step 3 and 4
    #     8. populate the hash created at step 0
    #     9. create a tree based on whatever framework you are using.
    
    # get the funding projects from the API. This API returns project(s) that is/are funding this target project
  	#fundingProjectsData = get_funding_project_details(n, componentListAsString)
  	#fundingProjects = fundingProjectsData['results'].select {|project| !project['provider_organisation'].nil? }
    
    def get_funding_project_details2(projectId, componentListAsString)
        fundingProjectsAPI = RestClient.get  api_simple_log(settings.oipa_api_url_solr + 'transaction?q=iati_identifier:'+componentListAsString+' AND transaction_type:1&rows=1000&fl=*' )
        fundingProjectsData = JSON.parse(fundingProjectsAPI)['response']['docs']
        finalProjectsList = {}
        fundingProjectsData.each do |p|
            if p.has_key?('transaction_provider_org_provider_activity_id')
                if !finalProjectsList.has_key?('transaction_provider_org_provider_activity_id')
                    fundingProjectDetails = get_project_title_description(p['transaction_provider_org_provider_activity_id'])
                    if !fundingProjectDetails.nil?
                        finalProjectsList[p['transaction_provider_org_provider_activity_id']] = {}
                        finalProjectsList[p['transaction_provider_org_provider_activity_id']]['fundingProjectId'] = fundingProjectDetails['iati_identifier']
                        finalProjectsList[p['transaction_provider_org_provider_activity_id']]['fundingProjectTitle'] = fundingProjectDetails.has_key?('title_narrative_first') ? fundingProjectDetails['title_narrative_first'] : 'N/A'
                        finalProjectsList[p['transaction_provider_org_provider_activity_id']]['fundingProjectDescription'] = fundingProjectDetails.has_key?('description_narrative_text') ? fundingProjectDetails['description_narrative_text'].first : 'N/A'
                        finalProjectsList[p['transaction_provider_org_provider_activity_id']]['fundingOrg'] = fundingProjectDetails['reporting_org_narrative'].first == 'UK - Department for International Development (DFID)' ? 'UK - Foreign, Commonwealth and Development Office (FCDO)' : fundingProjectDetails['reporting_org_narrative'].first
                        finalProjectsList[p['transaction_provider_org_provider_activity_id']]['fundingAmount'] = p['transaction_value'].to_f
                        finalProjectsList[p['transaction_provider_org_provider_activity_id']]['default_currency'] = fundingProjectDetails['default_currency']
                    end
                else
                    finalProjectsList[p['transaction_provider_org_provider_activity_id']]['fundingAmount'] = finalProjectsList['transaction_provider_org_provider_activity_id']['fundingAmount'] + p['transaction_value'].to_f
                end
            end
        end
        finalProjectsList
    end

    # get the partner/funded projects from the API. This API returns project(s) that is/are being funded by this project
	#fundedProjectsData = get_funded_project_details(n)
    def get_funded_project_details2(projectId, componentListAsString)
        fundedProjectsAPI = RestClient.get  api_simple_log(settings.oipa_api_url_solr + 'activity?fl=reporting_org_narrative,iati_identifier,title_narrative_first,description_narrative_text,budget_value,transaction_value,transaction_provider_org_provider_activity_id,transaction&q=transaction_provider_org_provider_activity_id:'+componentListAsString+'&sort=title_narrative_first asc&rows=500')
        fundedProjectsData = JSON.parse(fundedProjectsAPI)['response']['docs']
        fundedProjectsList = []
        fundedProjectsData.each do |p|
            if !p['iati_identifier'].include?(projectId)
                tempData = {}
                tempData['iati_identifier'] = p['iati_identifier']
                #tempData['reportingOrg'] = p.has_key?('reporting_org_narrative') ? p['reporting_org_narrative'].first : 'N/A'
                tempData['title'] = p.has_key?('title_narrative_first') ? p['title_narrative_first'] : 'N/A'
                #tempData['description'] = p.has_key?('description_narrative_text') ? p['description_narrative_text'].first : 'N/A'
                tempData['budget'] = p.has_key?('budget_value') ? p['budget_value'].first.to_f : 0.0
                fundedProjectsList.push(tempData)
            end
        end
        fundedProjectsList
    end

    def get_project_component_data2(project)
        components = Array.new
        if project.has_key?('related_activity_ref')
          project['related_activity_ref'].each do |component|
            if(component.to_s.include? project['iati_identifier'].to_s)
              begin
                pullActivityData = get_h1_project_details(component)
                componentData = {}
                begin
                  componentData['title'] = pullActivityData['title_narrative_first']
                rescue
                  componentData['title'] = 'N/A'
                end
                begin
                  componentData['activityID'] = pullActivityData['iati_identifier']
                rescue
                  componentData['title'] = 'N/A'
                end
                if (pullActivityData.has_key?('activity_date'))
                  if pullActivityData.has_key?('activity_date_start_common')
                    componentData['startDate'] = pullActivityData['activity_date_start_common']
                  else
                    componentData['startDate'] = 'N/A'
                  end
                  if pullActivityData.has_key?('activity_date_end_common')
                    componentData['endDate'] = pullActivityData['activity_date_end_common']
                  else
                    componentData['endDate'] = 'N/A'
                  end
                else
                  componentData['startDate'] = 'N/A'
                  componentData['endDate'] = 'N/A'
                end
                components.push(componentData)
              rescue
                puts 'Component does not exist in OIPA yet.'
              end
            end
          end
          components = components.sort_by{|component| component['activityID'].to_s}
        end
        components
      end

      def get_componentListAsString(projectid, componentData)
        componentListAsString = '(' + projectid + ' '
        if componentData.length > 0
          componentData.each do |c|
            componentListAsString = componentListAsString + c['activityID'] + ' '
          end
        end
        componentListAsString = componentListAsString + ')'
        componentListAsString
      end

      def get_h1_project_details2(projectId)
        oipa = RestClient.get  api_simple_log(settings.oipa_api_url_solr + 'activity?q=iati_identifier:'+projectId+'&fl=*')
        project = JSON.parse(oipa)
        project = project['response']['docs'][0]
        project
    end

    def get_component_list_as_string(projectId)
        projectData = get_h1_project_details2(projectId)
        componentData = get_project_component_data2(projectData)
        componentListAsString = get_componentListAsString(projectId, componentData)
        componentListAsString
    end

    def build_data(projectId)
      downstream_hash = {}
      downstream_hash[projectId] = {}
      parsed_keys = {}
      parsed_keys[projectId] = {}
      downstream_hash[projectId] = get_child_activities(projectId)
      # Second level of children
      tempSecondLevelChildren = downstream_hash[projectId].keys
      tempSecondLevelChildren.each do |c|
        if !parsed_keys.has_key?(c)
          parsed_keys[c] = {}
          downstream_hash[projectId][c]['child_activities'] = {}
          downstream_hash[projectId][c]['child_activities'] = get_child_activities(c)
        end
      end

      # Tertiary level of children
      tempSecondLevelChildren.each do |c|
        downstream_hash[projectId][c]['child_activities'].each_key do |key|
          if !parsed_keys.has_key?(key)
            parsed_keys[key] = {}
            downstream_hash[projectId][c]['child_activities'][key]['child_activities'] = {}
            downstream_hash[projectId][c]['child_activities'][key]['child_activities'] = get_child_activities(key)
          end
        end
      end

      # 4th level children data
      tempSecondLevelChildren.each do |c|
        downstream_hash[projectId][c]['child_activities'].each_key do |key|
          if downstream_hash[projectId][c]['child_activities'][key].has_key?('child_activities')
            downstream_hash[projectId][c]['child_activities'][key]['child_activities'].each_key do |key2|
              if !parsed_keys.has_key?(key2)
                parsed_keys[key2] = {}
                downstream_hash[projectId][c]['child_activities'][key]['child_activities'][key2]['child_activities'] = {}
                downstream_hash[projectId][c]['child_activities'][key]['child_activities'][key2]['child_activities'] = get_child_activities(key2)
              end
            end
          end
        end
      end

      # Prepare the tree for drawing
      final_tree = []
      # Prepare first tier tree 
      firstTier = []
      tempRoot = {}
      tempRoot['id'] = projectId
      final_tree.push(firstTier.push(tempRoot))

      # Prepare second tier tree
      secondTier = []
      thirdTiper = []
      fourthTier = []
      fifthTier = []
      tempSecondLevelChildren.each do |c|
        if push_to_correct_level(secondTier, c, projectId)
        else
          tempHashSecondLvl = {}
          tempHashSecondLvl['id'] = c
          tempHashSecondLvl['parents'] = Array[projectId]
          secondTier.push(tempHashSecondLvl)
        end
        downstream_hash[projectId][c]['child_activities'].each_key do |key|
          if push_to_correct_level(secondTier, key, c) || push_to_correct_level(thirdTiper, key, c)
          else
            tempHashThirdLvl = {}
            tempHashThirdLvl['id'] = key
            tempHashThirdLvl['parents'] = Array[c]
            thirdTiper.push(tempHashThirdLvl)
          end
          if downstream_hash[projectId][c]['child_activities'][key].has_key?('child_activities')
            downstream_hash[projectId][c]['child_activities'][key]['child_activities'].each_key do |key2|
              if push_to_correct_level(secondTier, key2, key) || push_to_correct_level(thirdTiper, key2, key) || push_to_correct_level(fourthTier, key2, key)
              else
                tempHashFourthLvl = {}
                tempHashFourthLvl['id'] = key2
                tempHashFourthLvl['parents'] = Array[key]
                fourthTier.push(tempHashFourthLvl)
              end
              if downstream_hash[projectId][c]['child_activities'][key]['child_activities'][key2].has_key? ('child_activities')
                downstream_hash[projectId][c]['child_activities'][key]['child_activities'][key2]['child_activities'].each_key do |key3|
                  if push_to_correct_level(secondTier, key3, key2) || push_to_correct_level(thirdTiper, key3, key2) || push_to_correct_level(fourthTier, key3, key2) || push_to_correct_level(fifthTier, key3, key2)
                  else
                    tempHashFifthLvl = {}
                    tempHashFifthLvl['id'] = key3
                    tempHashFifthLvl['parents'] = Array[key2]
                    fifthTier.push(tempHashFifthLvl)
                  end
                end
              end
            end
          end
        end
      end
      final_tree.push(secondTier)
      final_tree.push(thirdTiper)
      final_tree.push(fourthTier)
      final_tree.push(fifthTier)
      final_tree
    end


    def build_data_lite(projectId)
      downstream_hash = {}
      downstream_hash[projectId] = {}
      parsed_keys = {}
      parsed_keys[projectId] = {}
      downstream_hash[projectId] = get_child_activities(projectId)
      # Second level of children
      tempSecondLevelChildren = downstream_hash[projectId].keys
      tempSecondLevelChildren.each do |c|
        if !parsed_keys.has_key?(c)
          parsed_keys[c] = {}
          downstream_hash[projectId][c]['child_activities'] = {}
          downstream_hash[projectId][c]['child_activities'] = get_child_activities(c)
        end
      end

      # Tertiary level of children
      # tempSecondLevelChildren.each do |c|
      #   downstream_hash[projectId][c]['child_activities'].each_key do |key|
      #     if !parsed_keys.has_key?(key)
      #       parsed_keys[key] = {}
      #       downstream_hash[projectId][c]['child_activities'][key]['child_activities'] = {}
      #       downstream_hash[projectId][c]['child_activities'][key]['child_activities'] = get_child_activities(key)
      #     end
      #   end
      # end

      # 4th level children data
      # tempSecondLevelChildren.each do |c|
      #   downstream_hash[projectId][c]['child_activities'].each_key do |key|
      #     if downstream_hash[projectId][c]['child_activities'][key].has_key?('child_activities')
      #       downstream_hash[projectId][c]['child_activities'][key]['child_activities'].each_key do |key2|
      #         if !parsed_keys.has_key?(key2)
      #           parsed_keys[key2] = {}
      #           downstream_hash[projectId][c]['child_activities'][key]['child_activities'][key2]['child_activities'] = {}
      #           downstream_hash[projectId][c]['child_activities'][key]['child_activities'][key2]['child_activities'] = get_child_activities(key2)
      #         end
      #       end
      #     end
      #   end
      # end

      # Prepare the tree for drawing
      final_tree = []
      # Prepare first tier tree 
      firstTier = []
      tempRoot = {}
      tempRoot['id'] = projectId
      final_tree.push(firstTier.push(tempRoot))

      # Prepare second tier tree
      secondTier = []
      thirdTiper = []
      #fourthTier = []
      #fifthTier = []
      secondTierCount = 0
      thirdTierCount = 0
      tempSecondLevelChildren.each do |c|
        if push_to_correct_level(secondTier, c, projectId)
        else
          tempHashSecondLvl = {}
          tempHashSecondLvl['id'] = c
          tempHashSecondLvl['parents'] = Array[projectId]
          secondTier.push(tempHashSecondLvl)
          secondTierCount = secondTierCount + 1
        end
        downstream_hash[projectId][c]['child_activities'].each_key do |key|
          if push_to_correct_level(secondTier, key, c) || push_to_correct_level(thirdTiper, key, c)
          else
            tempHashThirdLvl = {}
            tempHashThirdLvl['id'] = key
            tempHashThirdLvl['parents'] = Array[c]
            thirdTiper.push(tempHashThirdLvl)
            thirdTierCount = thirdTierCount + 1
          end
          # if downstream_hash[projectId][c]['child_activities'][key].has_key?('child_activities')
          #   downstream_hash[projectId][c]['child_activities'][key]['child_activities'].each_key do |key2|
          #     if push_to_correct_level(secondTier, key2, key) || push_to_correct_level(thirdTiper, key2, key) || push_to_correct_level(fourthTier, key2, key)
          #     else
          #       tempHashFourthLvl = {}
          #       tempHashFourthLvl['id'] = key2
          #       tempHashFourthLvl['parents'] = Array[key]
          #       fourthTier.push(tempHashFourthLvl)
          #     end
          #     # if downstream_hash[projectId][c]['child_activities'][key]['child_activities'][key2].has_key? ('child_activities')
          #     #   downstream_hash[projectId][c]['child_activities'][key]['child_activities'][key2]['child_activities'].each_key do |key3|
          #     #     if push_to_correct_level(secondTier, key3, key2) || push_to_correct_level(thirdTiper, key3, key2) || push_to_correct_level(fourthTier, key3, key2) || push_to_correct_level(fifthTier, key3, key2)
          #     #     else
          #     #       tempHashFifthLvl = {}
          #     #       tempHashFifthLvl['id'] = key3
          #     #       tempHashFifthLvl['parents'] = Array[key2]
          #     #       fifthTier.push(tempHashFifthLvl)
          #     #     end
          #     #   end
          #     # end
          #   end
          # end
        end
      end
      #final_tree.push(secondTier)
      #final_tree.push(thirdTiper)
      #final_tree.push(fourthTier)
      #final_tree.push(fifthTier)
      #final_tree
      t = {}
      t['iati_identifier'] = projectId
      t['secondTierCount'] = secondTierCount
      t['thirdTierCount'] = thirdTierCount
      t
    end


    def push_to_correct_level(level, child, parent)
      level.each do |i|
        if i['id'].to_s == child.to_s
          i['parents'].push(parent)
          return true
        end
      end
      return false
    end

    def get_child_activities(projectId)
      puts projectId
      tempHash = {}
      componentListAsString = get_component_list_as_string(projectId)
      fundedProjects = get_funded_project_details2(projectId, componentListAsString)
      fundedProjects.each do |p|
        if !tempHash.has_key? (p['iati_identifier'])
          tempHash[p['iati_identifier']] = {}
          tempHash[p['iati_identifier']] = p
        else
          #downstream_hash[projectId][p['iati_identifier']].push(p)
        end
      end
      tempHash
    end
end