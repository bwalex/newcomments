require 'bundler'
Bundler.require(:default)


class Web < Sinatra::Base
  before do
    ActiveRecord::Base.connection_pool.connections.map(&:verify!)
  end


  get '/' do
    "Hello world."
  end
end
