module Invoicing
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration
      
      source_root File.expand_path("../templates", __FILE__)

      desc <<-CONTENT
        Copies the invoicing migration file to the migrations
        folder.
        
        Please run rake db:migrate once the installer is 
        complete.

  CONTENT

      def self.next_migration_number(dirname) #:nodoc:
        if ActiveRecord::Base.timestamped_migrations
          Time.now.utc.strftime("%Y%m%d%H%M%S")
        else
          "%.3d" % (current_migration_number(dirname) + 1)
        end
      end

      def create_migration_file
        migration_template 'migration.rb', 'db/migrate/create_invoicing_tables.rb'
      end
    end
  end
end
