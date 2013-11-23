require 'bundler'
Bundler.require(:default)

require './users'
require './articles'


class Site < ActiveRecord::Base
  has_many :site_users
  has_many :articles

  has_many :users, :through => :site_users,
                   :uniq => true
end
