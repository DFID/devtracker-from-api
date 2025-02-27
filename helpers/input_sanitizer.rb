module InputSanitizer
	def sanitize_input(string,type)
		case type
		when "e"
			#This one sanitizes an email input
			return string.gsub(/[^a-z0-9\s+_.@-]/,'')
		when "a"
			#Handles the free text search inputs
			return string.gsub(/[^a-zA-Z0-9.\s_\/\-]/,'')
		when "t"
			#Handles the telephone number inputs
			return string.gsub(/[^0-9+\s]/,'')
		when "p"
			#Handles the country codes, region codes and project IDs
			return string.gsub(/[^a-zA-Z0-9\-\s_]/,'')
		when "id"
			#Converts slashes to dashes and removes spaces from project IDs
			return string.gsub(/[\/']/,'-').gsub(/[\s]/,'').gsub(/[&]/,'-')
		when "newId"
			#Removes angle brackets and left ticks from the string to break possible code injection
			return string.to_s.gsub(/[\<\>\`]/, '')
		else
			#anything other than those specified will act similar to the case 'a' by default
			return string.gsub(/[^a-zA-Z0-9\s_\/\-]/,'')
		end
	end
end
