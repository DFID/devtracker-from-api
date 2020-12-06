#require "kramdown"
#require 'uri'

module OipaHelpers

  def non_dfid_data(projectCode)
    !projectCode[0, 4] == "GB-1"
  end

  def activityUrlOipa(projectCode,format)
   #settings.oipa_api_url + "activities/" + projectCode + "?format=" + format
   "/api/activities/" + projectCode + "/?format=" + format + "&fields=id,url,iati_identifier,reporting_organisation,title,descriptions,participating_organisations,other_identifier,activity_status,budget_not_provided,activity_dates,contact_info,activity_scope,recipient_countries,recipient_regions,locations,sectors,tags,country_budget_items,humanitarian,humanitarian_scope,policy_markers,collaboration_type,default_flow_type,default_finance_type,default_aid_type,default_tied_status,budgets,planned_disbursements,capital_spend,transactions,document_links,related_activities,legacy_data,conditions,results,crs_add,fss,last_updated_datetime,xml_lang,default_currency,hierarchy,linked_data_uri,activity_plus_child_aggregation,dataset,publisher,published_state,transaction_types"
  end

end

helpers OipaHelpers
