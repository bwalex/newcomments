require 'bundler'
Bundler.require(:default)

require_relative 'models/users'

class Web < Sinatra::Base
  use Rack::Flash

  before do
    puts "before"
    ActiveRecord::Base.connection_pool.connections.map(&:verify!)
  end


  after do
    puts "after"
    ActiveRecord::Base.clear_active_connections!
  end


  get '/' do
    redirect '/admin'
  end


  get '/logout' do
    session[:user] = nil
    redirect '/'
  end


  get '/login' do
    haml :login, :format => :html5
  end


  post '/login' do
    u = User.authenticate(params[:email], params[:password])

    if u == nil
      flash[:error] = "Invalid email or password"
      redirect '/login'
    else
      session[:user] = u.id
      redirect '/'
    end
  end


  before '/admin*' do
    begin
      @user = User.find(session[:user])
    rescue ActiveRecord::RecordNotFound
      redirect '/login'
    end
  end


  get '/admin' do
    redirect '/admin/sites'
  end


  get '/admin/sites' do
    @sites = @user.is_admin? ? Site.all : @user.sites

    haml :admin_sites, :layout => :admin_layout, :format => :html5,
      :locals => {
      :menu_sel => "sites",
    }
  end


  post '/admin/sites' do
    unless @user.is_admin?
      flash[:error] = "Only a global administrator can create new sites"
      redirect '/admin/sites'
    end

    begin
      Site.create!(:domain => params[:domain])
      flash[:success] = "Successfully created new site"
    rescue ActiveRecord::RecordInvalid => invalid
      flash[:error] = "Failed to create site because: " + invalid.message
    end

    redirect '/admin/sites'
  end


  get '/admin/account' do
    haml :admin_account, :layout => :admin_layout, :format => :html5,
      :locals => {
      :menu_sel => "account"
    }
  end


  post '/admin/account' do
    if params[:new_password].blank?
      flash[:error] = "Failed to change password because: new password is blank"
    else
      begin
        @user.new_password = params[:new_password]
        @user.new_password_confirmation = params[:new_password_confirmation]
        @user.save!
        flash[:success] = "Password changed successfully"
      rescue ActiveRecord::RecordInvalid => invalid
        flash[:error] = "Failed to change password because: " + invalid.message
      end
    end

    redirect '/admin/account'
  end



  get '/admin/global' do
    unless @user.is_admin?
      flash[:error] = "You are not an admin"
      redirect "/admin"
    end
    @users = User.all

    haml :admin_global, :layout => :admin_layout, :format => :html5,
      :locals => {
      :menu_sel => "global"
    }
  end


  post '/admin/global' do
    unless @user.is_admin?
      flash[:error] = "You are not an admin"
      redirect "/admin"
    end
    begin
      user_ids = (params[:user_delete] || []).map { |i| i.to_i }
      if user_ids.include?(@user.id)
        flash[:error] = "You cannot delete your own user"
        redirect "/admin/global"
      end

      puts "admin params: #{params[:admin]}"
      if params[:admin] and
         params[:admin].has_key?(@user.id.to_s) and
        (params[:admin][@user.id.to_s] != "admin")
        flash[:error] = "You cannot strip yourself of admin privileges"
        redirect "/admin/global"
      end

      params[:admin].each do |u_id, new_admin|
        u = User.find(u_id.to_i)
        u.admin = (new_admin == "admin")
        u.save!
      end

      User.where(:id => user_ids).destroy_all

      flash[:success] = "Changes saved successfully"
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "Something nasty happened - if it wasn't your fault, try again."
    rescue ActiveRecord::RecordInvalid => invalid
      flash[:error] = "Error updating user: #{invalid.message}"
    end
    redirect "/admin/global"
  end


  post '/admin/global/users_add' do
    unless @user.is_admin?
      flash[:error] = "You are not an admin"
      redirect "/admin"
    end
    begin
      user = User.create!(:email => params[:email],
                          :admin => false)

      NewUserEmailJob.new.async.perform(user.id)
      flash[:success] = "New user added successfully"
    rescue ActiveRecord::RecordInvalid => invalid
      flash[:error] = "Error adding new user: #{invalid.message}"
    end
    redirect "/admin/global"
  end


  before '/admin/sites/:site*' do
    begin
      @site = Site.find_by_domain!(params[:site])
      raise ActiveRecord::RecordNotFound unless @user.can? :access, @site
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "Site #{params[:site]} doesn't exist or you don't have access to it."
      redirect '/admin/sites'
    end
  end


  get '/admin/sites/:site' do
    @articles = @site.articles.order(:created_at => :desc)
    haml :admin_site, :layout => :admin_layout, :format => :html5,
      :locals => {
      :menu_sel => "sites"
    }
  end


  get '/admin/sites/:site/preferences' do
    puts "is subscribed? #{@user.subscribed_to?(@site)}"
    haml :admin_site_prefs, :layout => :admin_layout, :format => :html5,
      :locals => {
      :menu_sel => "sites"
    }
  end


  post '/admin/sites/:site/preferences' do
    @user.set_subscription_status(@site, !!params[:email_updates])
    flash[:success] = "Preferences saved successfully"
    redirect "/admin/sites/#{params[:site]}/preferences"
  end


  get '/admin/sites/:site/settings' do
    unless @user.can? :manage, @site
      flash[:error] = "You can't manage #{params[:site]}"
      redirect "/admin/sites/#{params[:site]}"
    end
    haml :admin_site_settings, :layout => :admin_layout, :format => :html5,
      :locals => {
      :menu_sel => "sites"
    }
  end


  post '/admin/sites/:site/settings' do
    unless @user.can? :manage, @site
      flash[:error] = "You can't manage #{params[:site]}"
      redirect "/admin/sites/#{params[:site]}"
    end
    begin
      @site.closed = !!params[:comments_closed]
      @site.save!
      flash[:success] = "Settings saved successfully"
    rescue ActiveRecord::RecordInvalid => invalid
      flash[:error] = "Error saving settings: #{invalid.message}"
    end
    redirect "/admin/sites/#{params[:site]}/settings"
  end


  get '/admin/sites/:site/users' do
    unless @user.can? :manage, @site
      flash[:error] = "You can't manage #{params[:site]}"
      redirect "/admin/sites/#{params[:site]}"
    end
    haml :admin_site_users, :layout => :admin_layout, :format => :html5,
      :locals => {
      :menu_sel => "sites"
    }
  end


  post '/admin/sites/:site/users' do
    unless @user.can? :manage, @site
      flash[:error] = "You can't manage #{params[:site]}"
      redirect "/admin/sites/#{params[:site]}"
    end
    begin
      params[:access_level].each do |su_id, new_level|
        su = @site.site_users.find(su_id.to_i)
        su.access_level = new_level.to_i
        su.save!
      end

      params[:user_delete] ||= []
      user_ids = []
      @site.site_users.where(:id => params[:user_delete].map { |i| i.to_i }).includes(:user).find_each { |su| user_ids << su.user.id }
      @site.site_users.where(:id => params[:user_delete].map { |i| i.to_i }).destroy_all
      @site.subscriptions.where(:user_id => user_ids).destroy_all
      flash[:success] = "Changes saved successfully"
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "Something nasty happened - if it wasn't your fault, try again."
    rescue ActiveRecord::RecordInvalid => invalid
      flash[:error] = "Error updating user: #{invalid.message}"
    end
    redirect "/admin/sites/#{params[:site]}/users"
  end


  post '/admin/sites/:site/users_add' do
    unless @user.can? :manage, @site
      flash[:error] = "You can't manage #{params[:site]}"
      redirect "/admin/sites/#{params[:site]}"
    end
    begin
      other = User.find_by_email!(params[:email])
      SiteUser.create!(:user => other,
                       :site => @site,
                       :access_level => SiteUser::ACCESS_LEVEL[:moderate])

      flash[:success] = "New user added successfully"
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "No user with email: #{params[:email]}"
    rescue ActiveRecord::RecordInvalid => invalid
      flash[:error] = "Error adding new user: #{invalid.message}"
    end
    redirect "/admin/sites/#{params[:site]}/users"
  end


  before '/admin/sites/:site/articles/:article*' do
    begin
      @article = Article.find_by_site_id_and_identifier!(@site.id, params[:article])
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "No such article: #{params[:article]}"
      redirect "/admin/sites/#{params[:site]}"
    end
  end


  get '/admin/sites/:site/articles/:article' do
    @comments = @article.comments.order(:created_at => :desc)
    haml :admin_article, :layout => :admin_layout, :format => :html5,
      :locals => {
      :menu_sel => "sites"
    }
  end


  post '/admin/sites/:site/articles/:article' do
    unless @user.can? :moderate, @site
      flash[:error] = "You can't moderate #{params[:site]}"
      redirect "/admin/sites/#{params[:site]}/articles/#{params[:article]}"
    end
    params["comment_delete"] ||= []
    @article.comments.where(:id => params["comment_delete"].map { |i| i.to_i }).destroy_all
    flash[:success] = "Successfully deleted selected comments"
    redirect "/admin/sites/#{params[:site]}/articles/#{params[:article]}"
  end


  post '/admin/sites/:site/articles/:article/settings' do
    unless @user.can? :manage, @site
      flash[:error] = "You can't manage #{params[:site]}"
      redirect "/admin/sites/#{params[:site]}/articles/#{params[:article]}"
    end
    begin
      @article.closed = (params[:comments_closed] == "true") ? true : false
      @article.save!
      flash[:success] = "Settings saved successfully"
    rescue ActiveRecord::RecordInvalid => invalid
      flash[:error] = "Error saving settings: #{invalid.message}"
    end
    redirect "/admin/sites/#{params[:site]}/articles/#{params[:article]}"
  end
end
