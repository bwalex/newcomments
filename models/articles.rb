require_relative 'sites'
require_relative 'comments'

class Article < ActiveRecord::Base
  belongs_to  :site
  has_many    :comments

  validates_presence_of :name
  validates_presence_of :identifier
  validates :name, :length => { :in => 1..255 }
  validates_format_of :url, :with => URI::regexp(%w(http https))
  validates_uniqueness_of :identifier, :scope => :site_id

  def can_comment?
    not (self[:closed] or self[:hidden] or self.site.closed)
  end

  def visible?
    not self[:hidden]
  end
end
