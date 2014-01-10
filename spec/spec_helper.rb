require 'bundler'
require 'ostruct'

ENV['RACK_ENV'] ||= 'test'

Bundler.require(:default, ENV['RACK_ENV'])
Bundler.require(:default, 'test')

require 'rack/test'
require 'capybara/rspec'
require 'capybara/poltergeist'

require_relative '../init.rb'
require_relative '../models/comments.rb'

ActiveSupport.on_load(:active_record) do
  cfg_file = 'config/database.yml'

  Kernel.abort "#{cfg_file} doesn't exist. Please create it and try again." unless File.exist? cfg_file

  cfg = YAML::load(File.open(cfg_file))

  Kernel.abort "#{cfg_file} doesn't contain any settings for the current environment (#{ENV['RACK_ENV']})" unless cfg.has_key? ENV['RACK_ENV']

  @db_cfg = cfg['test']

  ActiveRecord::Base.establish_connection(@db_cfg)
  #ActiveRecord::Base.logger = Logger.new(STDOUT)
end


RSpec.configure do |conf|
  conf.mock_with :rspec
  conf.expect_with :rspec

  conf.include Capybara::DSL
  conf.include Rack::Test::Methods
  conf.include FactoryGirl::Syntax::Methods

  conf.before(:suite) do
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean_with(:truncation)
  end

  conf.before(:each) do
    DatabaseCleaner.start
  end

  conf.after(:each) do
    DatabaseCleaner.clean
  end
end

FactoryGirl.define do
  factory :site do
    domain "example.com"
    closed false
  end

  factory :article do
    site

    sequence(:name) { |n| "Article #{n}" }
    sequence(:identifier) { |n| "article-identifier-#{n}" }
    sequence(:url) { |n| "http://example.com/foo/bar/#{n}-article" }

    closed false
    hidden false
  end

  factory :comment do
    article

    request(OpenStruct.new(ip: '127.0.0.1'))
    sequence(:name) { |n| "User #{n} Userus" }
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:hashed_email) { |n| "foobarhash" }
    sequence(:comment) { |n| "Comment foo bar moo #{n}. #{n} cows walk around." }
  end
end

APP = Rack::Builder.parse_file('config.ru').first
Capybara.app = APP
Capybara.javascript_driver = :poltergeist
Capybara.default_driver = :poltergeist
