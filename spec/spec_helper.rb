require 'bundler'

ENV['RACK_ENV'] ||= 'test'

Bundler.require(:default, ENV['RACK_ENV'])

require 'rack/test'

require_relative '../init.rb'

RSpec.configure do |conf|
  conf.mock_with :rspec
  conf.expect_with :rspec
  conf.include Rack::Test::Methods
end
