require 'bundler'

ENV['RACK_ENV'] ||= 'development'

Bundler.require(:default, ENV['RACK_ENV'])

Dir["#{File.dirname(__FILE__)}/initializers/**/*.rb"].sort.each { |ext| require ext }
