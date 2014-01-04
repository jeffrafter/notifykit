require 'rails/generators'
require 'rails/generators/active_record'

module Notifykit
  class InstallGenerator < Rails::Generators::Base
    include Rails::Generators::Migration

    desc "A notification system for your Rails app"

    def self.source_root
      @source_root ||= File.join(File.dirname(__FILE__), 'templates')
    end

    def generate_notifykit
      generate_migration("create_notifications")

      # Ensure the destination structure
      empty_directory "config"
      empty_directory "initializers"
      empty_directory "app"
      empty_directory "app/models"
      empty_directory "app/views"
      empty_directory "app/views/notifications"
      empty_directory "spec"
      empty_directory "spec/models"
      empty_directory "spec/controllers"
      empty_directory "spec/mailers"

      # Fill out some templates (for now, this is just straight copy)
      template "app/models/notification.rb", "app/models/notification.rb"
      template "app/mailers/notifications_mailer.rb", "app/mailers/notifications_mailer.rb"
      template "app/controllers/notifications_controller.rb", "app/controllers/notifications_controller.rb"

      # Don't treat these like templates
      copy_file "app/views/notifications/mailer.html.erb", "app/views/notifications/mailer.html.erb"
      copy_file "app/views/notifications/mailer.text.erb", "app/views/notifications/mailer.text.erb"
      copy_file "app/views/notifications/_welcome.html.erb", "app/views/notifications/_welcome.html.erb"
      copy_file "app/views/notifications/_welcome.text.erb", "app/views/notifications/_welcome.text.erb"

      # RSpec needs to be in the development group to be used in generators
      gem_group :test, :development do
        gem "rspec-rails"
        gem "shoulda-matchers"
        gem 'factory_girl_rails'
      end
    end

    def self.next_migration_number(dirname)
      ActiveRecord::Generators::Base.next_migration_number(dirname)
    end

    protected

    def generate_migration(filename)
      if self.class.migration_exists?("db/migrate", "#{filename}")
        say_status "skipped", "Migration #{filename}.rb already exists"
      else
        migration_template "db/migrate/#{filename}.rb", "db/migrate/#{filename}.rb"
      end
    end
  end
end

