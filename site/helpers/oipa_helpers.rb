#require "kramdown"
#require 'uri'

module OipaHelpers

  def has_funded_projects(projectCode)
    false
  end

  def non_dfid_data(projectCode)
    projectCode == "GB-1"
  end

  def activityUrlOipa(projectCode,format)
    "http://149.210.176.175/api/activities/" + projectCode + "?format=" + format
  end

end

helpers OipaHelpers