require 'bundler'
Bundler.require(:default)

ENV['RACK_ENV'] ||= 'development'

Dir["#{File.dirname(__FILE__)}/initializers/**/*.rb"].sort.each { |ext| require ext }
