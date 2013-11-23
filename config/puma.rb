workers 1
preload_app!

on_worker_boot do
  config = YAML::load(File.open('config/config.yml'))

  ActiveSupport.on_load(:active_record) do
    ActiveRecord::Base.establish_connection(YAML::load(File.open('config/database.yml')))
    ActiveRecord::Base.logger = Logger.new(STDOUT)
  end
end
