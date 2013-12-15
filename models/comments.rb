require 'bundler'
Bundler.require(:default)

require 'time'

require_relative 'articles'

class Comment < ActiveRecord::Base
  attr_accessor :request
  belongs_to    :article

  validates :email, :presence => true, :email => true, :length => { :in => 2..70 }
  validates :name, :length => { :in => 2..60 }
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
    self[:hashed_email] = Digest::MD5.hexdigest(self[:email].strip.downcase)
    return true
  end

  def save_request
    self[:ip] = @request.ip
    return true
  end

  def created_at
    (self[:created_at] != nil) ? self[:created_at].iso8601 : nil
  end

  def created_at_raw
    self[:created_at]
  end

  def as_json(options={})
    only = [
      :name,
      :email_hashed,
      :comment,
      :created_at
    ]

    methods = [
    ]

    super(
      :only => only,
      :methods => methods
    )
  end
end
