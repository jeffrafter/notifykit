require 'rails/generators'
require 'rails/generators/active_record'

module Notifykit
  class MessagesGenerator < Rails::Generators::Base
    include Rails::Generators::Migration

    class_option :test_mode, type: :boolean, default: false, description: "Run the generator in test mode"

    desc "Messages for bulk sending using notifications"

    def self.source_root
      @source_root ||= File.join(File.dirname(__FILE__), 'templates')
    end

    def generate_notifykit
      generate_migration("create_messages")

      # Ensure the destination structure
      empty_directory "app"
      empty_directory "app/models"
      empty_directory "app/views"
      empty_directory "app/views/notifications_mailer"
      empty_directory "spec"
      empty_directory "spec/models"

      # Fill out some templates (for now, this is just straight copy)
      template "app/models/message.rb", "app/models/message.rb"
      template "spec/models/message_spec.rb", "spec/models/message_spec.rb"
      template "spec/factories/message.rb", "spec/factories/message.rb"

      # Don't treat these like templates
      copy_file "app/views/notifications_mailer/_message.html.erb", "app/views/notifications_mailer/_message.html.erb"
      copy_file "app/views/notifications_mailer/_message.text.erb", "app/views/notifications_mailer/_message.text.erb"

      gem 'mustache'
      gem 'github-markup', require: 'github/markup'
      gem 'github-markdown'
      gem 'redcarpet'
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

