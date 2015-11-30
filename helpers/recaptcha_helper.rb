module RecaptchaHelper

	def verify_google_recptcha(secret_key,response)
	  status = `curl 'https://www.google.com/recaptcha/api/siteverify?secret=#{secret_key}&response=#{response}'`
	  puts 'showing Status Details below:'
	  puts status
	  hash = JSON.parse(status)
	  hash['success'] == true ? true : false
	end
end