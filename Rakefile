require 'bundler'
Bundler.require(:default)
Bundler.require(:default, 'test')

Dir["#{File.dirname(__FILE__)}/tasks/**/*.rake"].sort.each { |ext| load ext }

ENV['RACK_ENV'] ||= 'development'

require 'rubocop/rake_task'
Rubocop::RakeTask.new(:rubocop)

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
end

task :spec
