#require "kramdown"
#require 'uri'

module OipaHelpers

  def non_dfid_data(projectCode)
    !projectCode[0, 4] == "GB-1"
  end

  def activityUrlOipa(projectCode,format)
   "http://dfid-oipa.zz-clients.net/api/activities/" + projectCode + "?format=" + format
  end

end

helpers OipaHelpers