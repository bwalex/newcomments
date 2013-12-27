require 'yaml'
require 'logger'
require 'active_record'
require 'active_record/schema_dumper'
begin
  require 'foreigner'
rescue LoadError
end

namespace :db do
  task :config do
    ENV['RACK_ENV'] ||= 'development'
    config_file = 'config/database.yml'

    Kernel.abort "#{config_file} doesn't exist. Please create it and try again." unless File.exist? config_file

    conf = YAML::load(File.open(config_file))

    Kernel.abort "#{config_file} doesn't contain any settings for the current environment (#{ENV['RACK_ENV']})" unless conf.has_key? ENV['RACK_ENV']

    @db_config = conf[ENV['RACK_ENV']]
  end

  task :connect => :config do
    ActiveRecord::Base.establish_connection(@db_config)
    ActiveRecord::Base.logger = Logger.new(STDOUT) if ENV['VERBOSE'] == 'true'
    Foreigner.load if defined? Foreigner
  end

  desc "Migrate the database (options: VERSION=x, VERBOSE=false)."
  task :migrate => :connect do
    ActiveRecord::Migration.verbose = ENV['VERBOSE'] ? ENV['VERBOSE'] == 'true' : true
    ActiveRecord::Migrator.migrate 'db/migrate', ENV['VERSION'] ? ENV['VERSION'].to_i : nil
    Rake::Task["db:schema:dump"].invoke
  end

  desc "Rolls the schema back to the previous version (specify steps w/ STEP=n)."
  task :rollback => :connect do
    ActiveRecord::Migration.verbose = true
    ActiveRecord::Migrator.rollback 'db/migrate', ENV['STEP'] ? ENV['STEP'].to_i : 1
    Rake::Task["db:schema:dump"].invoke
  end

  desc "Pushes the schema to the next version (specify steps w/ STEP=n)."
  task :forward => :connect do
    ActiveRecord::Migration.verbose = true
    ActiveRecord::Migrator.forward 'db/migrate', ENV['STEP'] ? ENV['STEP'].to_i : 1
    Rake::Task["db:schema:dump"].invoke
  end

  desc 'Retrieves the current schema version number'
  task :version => :connect do
    puts "Current version: #{ActiveRecord::Migrator.current_version}"
  end

  namespace :schema do
    desc 'Output the schema to db/schema.rb'
    task :dump => :connect do
      file  = ENV['SCHEMA'] || 'db/schema.rb'
      File.open(file, 'w') do |f|
        ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, f)
      end
    end

    desc 'Load a schema.rb file into the database'
    task :load => :connect do
      file  = ENV['SCHEMA'] || 'db/schema.rb'
      unless File.exist?(file)
        Kernel.abort "#{file} doesn't exist yet. Run `rake db:migrate` to create it, then try again."
      end
      load(file)
    end
  end

  desc "create an ActiveRecord migration in ./db/migrate"
  task :create_migration do
    name = ENV['NAME']
    abort("no NAME specified. use `rake db:create_migration NAME=create_users`") if !name

    migrations_dir = File.join("db", "migrate")
    version = ENV['VERSION'] || Time.now.utc.strftime("%Y%m%d%H%M%S")
    filename = "#{version}_#{name}.rb"
    migration_name = name.gsub(/_(.)/) { $1.upcase }.gsub(/^(.)/) { $1.upcase }

    FileUtils.mkdir_p(migrations_dir)

    open(File.join(migrations_dir, filename), 'w') do |f|
      f << (<<-EOS).gsub("      ", "")
      class #{migration_name} < ActiveRecord::Migration
        def self.up
        end

        def self.down
        end
      end
      EOS
    end
  end

end
