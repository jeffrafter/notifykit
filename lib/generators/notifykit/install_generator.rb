require 'rails/generators'
require 'rails/generators/active_record'

module Notifykit
  class InstallGenerator < Rails::Generators::Base
    include Rails::Generators::Migration

    class_option :test_mode, type: :boolean, default: false, description: "Run the generator in test mode"

    desc "A notification system for your Rails app"

    def self.source_root
      @source_root ||= File.join(File.dirname(__FILE__), 'templates')
    end

    def generate_notifykit
      generate_migration("create_notifications")

      # Ensure the destination structure
      empty_directory "app"
      empty_directory "app/models"
      empty_directory "app/mailers"
      empty_directory "app/helpers"
      empty_directory "app/controllers"
      empty_directory "app/views"
      empty_directory "app/views/notifications"
      empty_directory "app/views/notifications_mailer"
      empty_directory "spec"
      empty_directory "spec/models"
      empty_directory "spec/controllers"
      empty_directory "spec/mailers"

      # Fill out some templates (for now, this is just straight copy)
      template "app/models/notification.rb", "app/models/notification.rb"
      template "app/mailers/notifications_mailer.rb", "app/mailers/notifications_mailer.rb"
      template "app/helpers/notifications_helper.rb", "app/helpers/notifications_helper.rb"
      template "app/controllers/notifications_controller.rb", "app/controllers/notifications_controller.rb"
      template "spec/factories/notification.rb", "spec/factories/notification.rb"
      template "spec/models/notification_spec.rb", "spec/models/notification_spec.rb"
      template "spec/helpers/notifications_helper_spec.rb", "spec/helpers/notifications_helper_spec.rb"
      template "spec/mailers/notifications_mailer_spec.rb", "spec/mailers/notifications_mailer_spec.rb"
      template "spec/controllers/notifications_controller_spec.rb", "spec/controllers/notifications_controller_spec.rb"

      # Don't treat these like templates
      copy_file "app/views/notifications_mailer/notify.html.erb", "app/views/notifications_mailer/notify.html.erb"
      copy_file "app/views/notifications_mailer/notify.text.erb", "app/views/notifications_mailer/notify.text.erb"
      copy_file "app/views/notifications_mailer/_welcome.html.erb", "app/views/notifications_mailer/_welcome.html.erb"
      copy_file "app/views/notifications_mailer/_welcome.text.erb", "app/views/notifications_mailer/_welcome.text.erb"

      # Though many of these actions are not idempotent, you must be able to click them in an email
      route "get   '/notifications/recent', to: 'notifications#recent', as: :notifications_recent"
      route "get   '/notifications/:token', to: 'notifications#click', as: :notification_click"
      route "get   '/notifications/:token/view', to: 'notifications#view', as: :notification_view"
      route "get   '/notifications/:token/read', to: 'notifications#read', as: :notification_read"
      route "get   '/notifications/:token/ignore', to: 'notifications#ignore', as: :notification_ignore"
      route "get   '/notifications/:token/cancel', to: 'notifications#cancel', as: :notification_cancel"
      route "get   '/notifications/:token/unsubscribe', to: 'notifications#unsubscribe', as: :notification_unsubscribe"

      if options.test_mode?
        route "root   'welcome#index'"
        route "get    '/help', to: 'help#index', as: :help"
        route "get    '/privacy', to: 'privacy#index', as: :privacy"
        route "get    '/terms', to: 'terms#index', as: :terms"
      end

      # Adjust the user
      inject_into_class "app/models/user.rb", User, "has_many :notifications\n"

      # Technically, we aren't inserting this at the end of the class, but the end of the RSpec::Configure
      insert_at_end_of_class "spec/spec_helper.rb", "spec/spec_helper.rb"

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

    def insert_at_end_of_file(filename, source)
      source = File.expand_path(find_in_source_paths(source.to_s))
      context = instance_eval('binding')
      content = ERB.new(::File.binread(source), nil, '-', '@output_buffer').result(context)
      insert_into_file filename, "#{content}\n", before: /\z/
    end

    def insert_at_end_of_class(filename, source)
      source = File.expand_path(find_in_source_paths(source.to_s))
      context = instance_eval('binding')
      content = ERB.new(::File.binread(source), nil, '-', '@output_buffer').result(context)
      insert_into_file filename, "#{content}\n", before: /end\n*\z/
    end

    def generate_migration(filename)
      if self.class.migration_exists?("db/migrate", "#{filename}")
        say_status "skipped", "Migration #{filename}.rb already exists"
      else
        migration_template "db/migrate/#{filename}.rb", "db/migrate/#{filename}.rb"
      end
    end
  end
end

