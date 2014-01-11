workers 1
preload_app!
pidfile "puma.pid"

on_worker_boot do
  puts "Rack environment: #{ENV['RACK_ENV']}"
  ActiveSupport.on_load(:active_record) do
    cfg_file = 'config/database.yml'

    Kernel.abort "#{cfg_file} doesn't exist. Please create it and try again." unless File.exist? cfg_file

    cfg = YAML::load(File.open(cfg_file))

    Kernel.abort "#{cfg_file} doesn't contain any settings for the current environment (#{ENV['RACK_ENV']})" unless cfg.has_key? ENV['RACK_ENV']

    @db_cfg = cfg[ENV['RACK_ENV']]

    ActiveRecord::Base.establish_connection(@db_cfg)
    ActiveRecord::Base.logger = Logger.new(STDOUT) unless ENV['RACK_ENV'] == 'production'
  end
end
