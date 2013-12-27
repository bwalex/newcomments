require 'grape/middleware/base'
require 'active_record/base'

class GrapeARMiddleware < Grape::Middleware::Base
  def call!(env)
    # Checkout connection
    ActiveRecord::Base.connection_pool.connections.map(&:verify!)

    status, headers, bodies = catch(:error) do
      @app.call(env)
    end

    # Return connection
    ActiveRecord::Base.clear_active_connections!

    # If status is a hash, something threw :error, so we need to
    # rethrow it.
    # Otherwise it's a normal response.
    if status.is_a?(Hash)
      throw :error, status
    else
      [status, headers, bodies]
    end
  end
end
