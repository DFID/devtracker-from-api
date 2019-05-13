module ErrorHandlerHelper

	# error nothingFound do
	#   status 404
	#   settings.devtracker_page_title = "Error 404(This item is not found anywhere!)"
	#   erb :'notFound', :layout => :'layouts/layout'
	# end

	error MyCustomError do
  		'So what happened was...'
	end
end