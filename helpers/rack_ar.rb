require 'active_record/base'

class RackARMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    ActiveRecord::Base.connection_pool.connections.map(&:verify!)

    response = @app.call(env)
    response[2] = ::Rack::BodyProxy.new(response[2]) do
      ActiveRecord::Base.clear_active_connections!
    end

    response
  rescue Exception
    ActiveRecord::Base.clear_active_connections!
    raise
  end
end
