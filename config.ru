require 'bundler'
Bundler.require(:default)

require './web'
require './api'

use Rack::Session::Cookie,
  :expire_after => 14400,
  :secret       => 'foobar'
run Rack::Cascade.new [API, Web]
