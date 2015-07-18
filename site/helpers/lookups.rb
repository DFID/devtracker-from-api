module Lookups

  def country_name(code)
    (@cms_db['countries'].find_one({ 'code' => code }) || { "name" => "" })["name"]
  end

  def region_name(code)
    (@cms_db['regions'].find_one({ 'code' => code }) || { "name" => "" })["name"]
  end

  def currency_symbol(code)  	

  	case code
  	when "GBP", ""
  		nil
	  when "USD"
		  "$"
	  else
		  code
  	end
    
  end	

end