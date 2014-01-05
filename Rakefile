require 'bundler'
Bundler.require(:default)
Bundler.require(:default, 'test')

Dir["#{File.dirname(__FILE__)}/tasks/**/*.rake"].sort.each { |ext| load ext }

ENV['RACK_ENV'] ||= 'development'

require 'rubocop/rake_task'
Rubocop::RakeTask.new(:rubocop)
