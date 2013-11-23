require 'bundler'
Bundler.require(:default)

require_relative 'users'
require_relative 'articles'


class Site < ActiveRecord::Base
  has_many :site_users
  has_many :articles

  has_many :users, -> { where uniq: true },
                      :through => :site_users
end
