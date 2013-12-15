require 'bundler'
Bundler.require(:default)

require 'erb'

require_relative '../models/users'
require_relative '../models/sites'
require_relative '../models/comments'


class NewCommentEmailJob
  include SuckerPunch::Job

  def perform(comment_id)
    template = ERB.new(File.open(File.join(File.expand_path(File.dirname(__FILE__)), '../views/emails/new_comment.erb')).read)
    ActiveRecord::Base.connection_pool.with_connection do
      begin
        comment = Comment.find(comment_id)
        article = comment.article
        site = article.site
        Subscription.where(:site => site).includes(:user).find_each do |sub|
          user = sub.user
          puts "Sending mail to #{user.email} with: #{template.result(binding)}"
          Pony.mail(
            :to => user.email,
            :subject => "New comment on #{site.domain}",
            :body => template.result(binding)
          )
        end
      rescue ActiveRecord::RecordNotFound
        puts "--> things went south..."
      end
    end
  end
end


class NewUserEmailJob
  include SuckerPunch::Job

  def perform(user_id)
    template = ERB.new(File.open(File.join(File.expand_path(File.dirname(__FILE__)), '../views/emails/new_user.erb')).read)
    ActiveRecord::Base.connection_pool.with_connection do
      begin
        user = User.find(user_id)
        pass = SecureRandom.hex(8)
        user.new_password = pass
        user.new_password_confirmation = pass
        user.save!
        Pony.mail(
          :to => user.email,
          :subject => "Account created!",
          :body => template.result(binding)
        )
      rescue ActiveRecord::RecordNotFound
        puts "--> things went south..."
      end
    end
  end
end
