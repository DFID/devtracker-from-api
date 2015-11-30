module RecaptchaHelper

	# config/initializers/recaptcha.rb
	Recaptcha.configure do |config|
	  config.public_key  = '6LfZ_BETAAAAAEg0yGu8KC0Y4nOliA9Y_rgVt0RT'
	  config.private_key = '6LfZ_BETAAAAAOc1NDbTmOZmsaxdRqbqDUem5KQZ'
	  # Uncomment the following line if you are using a proxy server:
	  # config.proxy = 'http://myproxy.com.au:8080'
	end
end