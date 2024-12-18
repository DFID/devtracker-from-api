require "rubygems"
require "json"
require "net/http"
require "uri"
 
def r4DApiDocFetch(projectId)
	
	begin
		uri_str = URI.escape("http://api.linkeddev.swirrl.com/openapi/r4d/get/research_outputs/"+projectId+".json?per_project=5")
		
		uri = URI.parse(uri_str)
 
		http = Net::HTTP.new(uri.host, uri.port)
		request = Net::HTTP::Get.new(uri.request_uri)
 		http.read_timeout = 500

		response = http.request(request)
 
		if response.code == "200"
			result = JSON.parse(response.body)['results']		
		end

	rescue SystemCallError => theSystemCallError
  		""
	end

end

# def getR4DSearchLink(object_id)

# 	search_uri = "http://r4d.fcdo.gov.uk/Search/SearchResults.aspx?search=advancedsearch&SearchType=3&Projects=false&Documents=true&DocumentsOnly=true&ProjectID="+object_id

# 	search_uri
	
# end

def getR4DDocsCountNotShowing(output_count)
		output_count.to_i - 5 
end

def get_document_category(projectId)
	oipa = RestClient.get  api_simple_log(settings.oipa_api_url + "activities/#{projectId}/?format=json")
  	project = JSON.parse(oipa)
  	documents=project['document_links']

  	if documents.length>0 then
  		result = "";
  		documents.each do |document|
  			if !document['category']['code'].nil? then 
  				result += document_category(document['category']['code'].to_s.strip) + '#' 
  			end
  		end
  		result = result.chop!
  	else
  		result=""
  	end		
end
