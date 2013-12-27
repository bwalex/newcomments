require 'yaml'
require 'pony'

# Setup mailer
cfg_file = 'config/mail.yml'

Kernel.abort "#{cfg_file} doesn't exist. Please create it and try again." unless File.exist? cfg_file

cfg = YAML::load(File.open(cfg_file))

Kernel.abort "#{cfg_file} doesn't contain any settings for the current environment (#{ENV['RACK_ENV']})" unless cfg.has_key? ENV['RACK_ENV']

@mail_cfg = cfg[ENV['RACK_ENV']]

mailopts = {
  :from => @mail_cfg['from'],
  :via  => @mail_cfg['via'].to_sym
}

if (@mail_cfg['via'].to_sym == :smtp)
  mailopts[:via_options] = {
    :address              => @mail_cfg['server']['address'],
    :port                 => @mail_cfg['server']['port'],
    :enable_starttls_auto => @mail_cfg['server']['enable_starttls_auto'],
    :user_name            => @mail_cfg['server']['user_name'],
    :password             => @mail_cfg['server']['password'],
    :authentication       => @mail_cfg['server']['authentication']
  }
end

Pony.options = mailopts
