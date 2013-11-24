require 'bundler'
Bundler.require(:default)


class API < Grape::API
  version 'v1', using: :header, vendor: 'comments'
  format :json
  prefix '/api'


  before do
    ActiveRecord::Base.connection_pool.connections.map(&:verify!)
  end


  resource :comments do
    desc "Get all comments for an article."
    params do
      requires :site_name,    type: String, desc: "Site this comment is posted on."
      requires :article_name, type: String, desc: "Article this comments refers to."
      requires :article_hash, type: String, desc: "Article this comments refers to."
    end
    get do
      site = Site.find_by_name!(params[:site_name])
      article = Article.find_by_hash!(params[:article_hash])
      article.comments
    end


    desc "Create a comment."
    params do
      requires :site_name,    type: String, desc: "Site this comment is posted on."
      requires :article_name, type: String, desc: "Article this comments refers to."
      requires :article_hash, type: String, desc: "Article this comments refers to."
      requires :email,        type: String, desc: "Your email."
      requires :name,         type: String, desc: "Your name."
      requires :comment,      type: String, desc: "The actual comment."
    end
    post do
      site = Site.find_by_name!(params[:site_name])
      article = Article.find_or_create_by_hash!(params[:article_hash]) do |a|
        a.site = site
        a.name = params[:article_name]
        a.hash = params[:article_hash]
      end
      article.comments.create!({
        :name    => params[:name],
        :email   => params[:email],
        :comment => params[:comment],
        :request => request
      })
    end
  end
end
