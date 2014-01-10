require_relative '../../models/users'

class DefaultUser < ActiveRecord::Migration
  def self.up
    User.create!(
      :email => "root@example.com",
      :new_password => "root",
      :new_password_confirmation => "root",
      :admin => true
    )
  end

  def self.down
    user = User.where(:email => "root@example.com").first
    user.destroy()
  end
end
