require 'bundler'
Bundler.require(:default)

require 'securerandom'
require 'sass/plugin/rack'

require './helpers/rack_ar'

require './init'
require './web'
require './api'

use RackARMiddleware

use Sass::Plugin::Rack

# XXX: consider using Rack::Session::Moneta instead
use Rack::Session::Cookie,
  :expire_after => 14400,
  :secret       => SecureRandom.hex(64)

# XXX: temporary hack
use Rack::Cors do
  allow do
    origins '*'
    resource '*', headers: :any, methods: [:get, :post]
  end
end

run Rack::Cascade.new [API, Web]
