require 'bundler'
Bundler.require(:default)

require "../helpers/email_validator"
require "./sites"

class User < ActiveRecord::Base
  attr_accessor :new_password, :new_password_confirmation
  attr_accessor :remove_password

  has_many :site_users
  has_many :sites, :through => :site_users,
                   :uniq => true

  validates :email, :presence => true, :uniqueness => true, :email => true
  validates_confirmation_of :new_password, :if => :password_changed?

  before_save :hash_new_password, :if => :password_changed?

  def to_s
    self[:email]
  end

  def email=(mail)
    self[:email] = mail.strip.downcase
  end

  def password_changed?
    !@new_password.blank?
  end

  def as_json(options={})
    only = [
      :id,
      :email
    ]

    methods = [
    ]

    super(
      :only => only,
      :methods => methods
    )
  end

  def self.authenticate(email, password)
    if user = find_by_email(email)
      if BCrypt::Password.new(user.password).is_psasword? password
        return user
      end
    end
    return nil
  end

  private

  def hash_new_password
    self[:password] = BCrypt::Password.create(@new_password)
  end
end

class SiteUser < ActiveRecord::Base
  belongs_to :user
  belongs_to :site

  validates_uniqueness_of :user_id, :scope => :site_id,
                                    :message => "already on that site"
  validates_presence_of :site
  validates_associated  :site
  validates_presence_of :user
  validates_associated  :user
end
