require 'bundler'
Bundler.require(:default)

require './sites'
require './comments'

class Article < ActiveRecord::Base
  belongs_to  :site
  has_many    :comments

  validates_presence_of :name
  validates_presence_of :hash
  validates :name, :length => { :in => 1..255 }
  validates_uniqueness_of :hash
end
