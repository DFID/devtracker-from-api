module InputSanitizer
	def sanitize_input(string,type)
		case type
		when "e"
			#This one sanitizes an email input
			return string.gsub(/[^a-z0-9+_.@-\s]/,'')
		when "a"
			#Handles the free text search inputs
			return string.gsub(/[^a-zA-Z0-9_\/\-\s]/,'')
		else
			#anything other than those specified will act similar to the case 'a' by default
			return string.gsub(/[^a-zA-Z0-9_\/\-\s]/,'')
		end
	end
end
