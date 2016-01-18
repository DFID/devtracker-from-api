#require "kramdown"
#require 'uri'

module OipaHelpers

  def non_dfid_data(projectCode)
    !projectCode[0, 4] == "GB-1"
  end

  def activityUrlOipa(projectCode,format)
   #settings.oipa_api_url + "activities/" + projectCode + "?format=" + format
   "/api/activities/" + projectCode + "/?format=" + format
  end

end

helpers OipaHelpers
