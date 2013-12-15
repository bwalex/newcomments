require 'bundler'
Bundler.require(:default)

require 'securerandom'
require 'sass/plugin/rack'
require './config/sass'
require './web'
require './api'


# Setup mailer
mailcfg = YAML::load(File.open('config/mail.yml'))
mailopts = {
  :from => mailcfg['from'],
  :via  => mailcfg['via'].to_sym
}

if (mailcfg['via'].to_sym == :smtp)
  mailopts[:via_options] = {
    :address => mailcfg['server']['address'],
    :port => mailcfg['server']['port'],
    :enable_starttls_auto => mailcfg['server']['enable_starttls_auto'],
    :user_name => mailcfg['server']['user_name'],
    :password => mailcfg['server']['password'],
    :authentication => mailcfg['server']['authentication']
  }
end

Pony.options = mailopts


use Sass::Plugin::Rack

# XXX: consider using Rack::Session::Moneta instead
use Rack::Session::Cookie,
  :expire_after => 14400,
  :secret       => SecureRandom.hex(64)

use Rack::Cors do
  allow do
    origins '*'
    resource '*', headers: :any, methods: [:get, :post]
  end
end


run Rack::Cascade.new [API, Web]
