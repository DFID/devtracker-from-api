# test_helper.rb
ENV['RACK_ENV'] = 'test'
require 'minitest/autorun'
require 'rack/test'

require 'coveralls'
Coveralls.wear!

require File.expand_path '../../devtracker.rb', __FILE__
