require 'digest/md5'

require_relative "../helpers/email_validator"
require_relative "sites"

class User < ActiveRecord::Base
  attr_accessor :new_password, :new_password_confirmation
  attr_accessor :remove_password

  has_many :site_users
  has_many :sites, :through => :site_users

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
      if BCrypt::Password.new(user.password).is_password? password
        return user
      end
    end
    return nil
  end

  def is_admin?
    return self[:admin]
  end

  def can?(type, site)
    return true if self.is_admin?
    begin
      su = SiteUser.find_by_site_id_and_user_id!(site.id, self.id)
      return (su.access_level >= SiteUser::ACCESS_LEVEL[type])
    rescue ActiveRecord::RecordNotFound
      return false
    end
  end

  def subscribed_to?(site)
    Subscription.where(:site => site, :user => self).exists?
  end

  def set_subscription_status(site, subscribed)
    begin
      sub = Subscription.find_by_site_id_and_user_id!(site.id, self.id)
      sub.destroy if not subscribed
    rescue ActiveRecord::RecordNotFound
      Subscription.create!(:user => self, :site => site) if subscribed
    end
  end

  private

  def hash_new_password
    self[:password] = BCrypt::Password.create(@new_password)
  end
end

class SiteUser < ActiveRecord::Base
  ACCESS_LEVEL = {
    :access   => 0,
    :moderate => 1,
    :manage   => 2
  }
  belongs_to :user
  belongs_to :site

  validates_uniqueness_of :user_id, :scope => :site_id,
                                    :message => "already on that site"

  validates_presence_of :site
  validates_associated  :site
  validates_presence_of :user
  validates_associated  :user

  validates :access_level, numericality: { :only_integer => true, 
                                           :less_than_or_equal_to    => ACCESS_LEVEL[:manage],
                                           :greater_than_or_equal_to => ACCESS_LEVEL[:access] }
end

class Subscription < ActiveRecord::Base
  belongs_to :user
  belongs_to :site

  validates_uniqueness_of :user_id, :scope => :site_id,
                                    :message => "already subscribed to site"
  validates_presence_of :site
  validates_associated  :site
  validates_presence_of :user
  validates_associated  :user
end
