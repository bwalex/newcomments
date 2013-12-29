require_relative 'users'
require_relative 'articles'


class Site < ActiveRecord::Base
  has_many :site_users
  has_many :subscriptions
  has_many :articles

  has_many :users, :through => :site_users

  validates :domain, :length => { :minimum => 4 }
  validates_uniqueness_of :domain

  def can_comment?
    not self[:closed]
  end
end
