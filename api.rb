require 'bundler'
Bundler.require(:default)

require_relative 'helpers/grape_ar'
require_relative 'helpers/recaptcha'
require_relative 'workers/email_worker'

class API < Grape::API
  use GrapeARMiddleware

  version 'v1', using: :header, vendor: 'comments'
  format :json
  prefix '/api'

  resource :comments do

    desc "Check if comments are open."
    params do
      requires :site_domain,        type: String, desc: "Site this comment is posted on."
      requires :article_identifier, type: String, desc: "Article this comments refers to."
    end
    get :open do
      begin
        site = Site.find_by_domain!(params[:site_domain])
      rescue ActiveRecord::RecordNotFound
        error!({ "error" => "Site not found"}, 400)
      end

      begin
        article = Article.find_by_site_id_and_identifier!(site.id, params[:article_identifier])
        { "can_comment" => article.can_comment? }
      rescue ActiveRecord::RecordNotFound
        { "can_comment" => site.can_comment? }
      end
    end


    desc "Get all comments for an article."
    params do
      requires :site_domain,        type: String, desc: "Site this comment is posted on."
      requires :article_identifier, type: String, desc: "Article this comments refers to."
    end
    get do
      begin
        site = Site.find_by_domain!(params[:site_domain])
      rescue ActiveRecord::RecordNotFound
        error!({ "error" => "site", "error_code" => "Site not found"}, 400)
      end

      begin
        article = Article.find_by_site_id_and_identifier!(site.id, params[:article_identifier])
        article.visible? ? article.comments.order(:created_at).to_a : []
      rescue ActiveRecord::RecordNotFound
        []
      end
    end


    desc "Create a comment."
    params do
      requires :captcha_challenge,  type: String, desc: "Captcha challenge."
      requires :captcha_response,   type: String, desc: "Captcha response."

      requires :site_domain,        type: String, desc: "Site this comment is posted on."
      requires :article_name,       type: String, desc: "Article this comments refers to."
      requires :article_url,        type: String, desc: "Article this comments refers to."
      requires :article_identifier, type: String, desc: "Article this comments refers to."
      requires :email,              type: String, desc: "Your email."
      requires :name,               type: String, desc: "Your name."
      requires :comment,            type: String, desc: "The actual comment."
    end
    post do
      ok, error_code = Recaptcha.verify?(
        :remote_ip => request.ip,
        :challenge => params[:captcha_challenge],
        :response  => params[:captcha_response]
      )
      error!({ "error" => "captcha", "error_code" => error_code}, 403) unless ok

      begin
        site = Site.find_by_domain!(params[:site_domain])
      rescue ActiveRecord::RecordNotFound
        error!({ "error" => "site", "error_code" => "Site not found"}, 400)
      end

      begin
        article = Article.find_or_create_by_site_id_and_identifier!(site.id, params[:article_identifier]) do |a|
          a.site = site
          a.name = params[:article_name]
          a.url = params[:article_url]
          a.identifier = params[:article_identifier]
        end
      rescue ActiveRecord::RecordInvalid => invalid
        error!({ "error" => "article", "error_code" => invalid.record.errors}, 400)
      end

      unless article.can_comment?
        error!({ "error" => "closed"}, 403)
      end

      begin
        comment = article.comments.create!({
          :name    => params[:name],
          :email   => params[:email],
          :comment => params[:comment],
          :request => request
        })
        article.touch
        NewCommentEmailJob.new.async.perform(comment.id)
      rescue ActiveRecord::RecordInvalid => invalid
        error!({ "error" => "comment", "error_code" => invalid.record.errors}, 400)
      end
    end


  end



end
