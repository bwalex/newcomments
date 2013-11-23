require 'bundler'
Bundler.require(:default)

require './articles'

class Comment < ActiveRecord::Base
  attr_accessor :request
  belongs_to    :article

  validates :email, :presence => true, :email => true
  validates :name, :length => { :in => 2..255 }
  validates :comment, :length => { :minimum => 2 }

  before_save   :hash_mail
  before_save   :save_request
  before_save   :sanitize_comment

  def sanitize_comment
    self[:comment] = Sanitize.clean(self[:comment].gsub(/\n/, '<br>'), Sanitize::Config::BASIC)
    return true
  end

  def email= mail
    self[:email] = mail.strip.downcase
  end

  def hash_mail
    self[:hashed_mail] = Digest::MD5.hexdigest(self[:email].strip.downcase)
    return true
  end

  def save_request
    self[:ip] = @request.ip
    return true
  end

  def human_created_at
    return (self[:created_at] != nil) ? self[:created_at].strftime("%d/%m/%Y - %H:%M") : nil
  end

  def human_updated_at
    return (self[:updated_at] != nil) ? self[:updated_at].strftime("%d/%m/%Y - %H:%M") : nil
  end
end
