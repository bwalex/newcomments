worker_processes 1
preload_app true

timeout 30
listen "127.0.0.1:9292"

after_fork do |server, worker|
  config = YAML::load(File.open('config/config.yml'))

  ActiveSupport.on_load(:active_record) do
    ActiveRecord::Base.establish_connection(YAML::load(File.open('config/database.yml')))
    ActiveRecord::Base.logger = Logger.new(STDOUT)
  end
end
