require 'bundler'
Bundler.require(:default)


class API < Grape::API
  before do
    ActiveRecord::Base.connection_pool.connections.map(&:verify!)
  end
  
  get :hello do
    {hello: "world"}
  end
end

