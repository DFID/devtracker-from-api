require "helpers/project_helpers"

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

end