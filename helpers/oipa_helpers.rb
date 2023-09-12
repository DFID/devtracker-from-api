#require "kramdown"
#require 'uri'

module OipaHelpers

  def non_dfid_data(projectCode)
    !projectCode[0, 4] == "GB-1"
  end

  def activityUrlOipa(projectCode,format)
   #settings.oipa_api_url + "activities/" + projectCode + "?format=" + format
   u = ''
   if request.url.start_with?('https://devtracker.')
    u = u + settings.prod_api_url
   else
    u = u + settings.dev_api_url
   end
   u+"/search/activity/?q=iati_identifier:" + projectCode + "&fl=*&format=" + format
  end

end

helpers OipaHelpers
