require 'bundler'
Bundler.require(:default)

Dir["#{File.dirname(__FILE__)}/tasks/**/*.rake"].sort.each { |ext| load ext }

ENV['RACK_ENV'] ||= 'development'

Bundler.require(:default, ENV['RACK_ENV'])

begin
  require 'rubocop/rake_task'
  Rubocop::RakeTask.new(:rubocop)
rescue LoadError
  puts "Could not load rubocop. Skipping."
end

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec) do |spec|
    spec.pattern = 'spec/**/*_spec.rb'
  end

  task :spec
rescue LoadError
  puts "Could not load rspec. Skipping."
end
