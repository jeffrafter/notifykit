require "bundler/gem_tasks"
require 'rspec/core/rake_task'

gem_name = :notifykit

task :spec => ["generator:cleanup", "generator:prepare", "generator:#{gem_name}"] do
  system "cd spec/tmp/sample; bundle exec rspec --color"
end

# When using sed to replace in place, don't rely on -i for POSIX compatibility
def sed(command, filename)
  system "sed '#{command}' #{filename} > #{filename}.tmp && mv #{filename}.tmp #{filename}"
end

namespace :generator do
  desc "Cleans up the sample app before running the generator"
  task :cleanup do
    FileUtils.rm_rf("spec/tmp/sample") if Dir.exist?("spec/tmp/sample") if ENV['SKIP_CLEANUP'].nil?
  end

  desc "Prepare the sample app before running the generator"
  task :prepare do
    next if Dir.exist?("spec/tmp/sample")

    FileUtils.mkdir_p("spec/tmp")

    system "cd spec/tmp && rails new sample --skip-spring"
    system "cp .ruby-version spec/tmp/sample"

    # bundle
    gem_root = File.expand_path(File.dirname(__FILE__))
    system "echo \"gem 'rspec-rails'\" >> spec/tmp/sample/Gemfile"
    system "echo \"gem 'factory_girl_rails'\" >> spec/tmp/sample/Gemfile"
    system "echo \"gem '#{gem_name}', :path => '#{gem_root}'\" >> spec/tmp/sample/Gemfile"

    system "cd spec/tmp/sample; bundle install"
    system "cd spec/tmp/sample; bin/rails g rspec:install"

    # Make sure rails helper loads the factory girl support file
    sed("s/# Dir/Dir/", "spec/tmp/sample/spec/rails_helper.rb")

    # Open up the root route for specs
    # Make a thing and a user
    system "cd spec/tmp/sample; bin/rails g scaffold thing name:string mood:string"
    system "cd spec/tmp/sample; bin/rails g scaffold user full_name:string first_name:string last_name:string email:string"
  end

  # This task is not used unless you need to test the generator with an alternate database
  # such as mysql or postgres. By default the sample application utilize sqlite3
  desc "Prepares the application with an alternate database"
  task :database do
    puts "==  Configuring the database =================================================="
    system "cp config/database.yml.example spec/tmp/sample/config/database.yml"
    system "cd spec/tmp/sample; bin/rake db:migrate:reset"
  end

  desc "Run the #{gem_name} generator"
  task gem_name do
    system "cd spec/tmp/sample; bin/rails g #{gem_name}:install --force --test_mode && bin/rake db:migrate"
    system "cd spec/tmp/sample; bin/rails g #{gem_name}:messages --force --test_mode && bin/rake db:migrate"
    system "cd spec/tmp/sample; bin/rake db:migrate RAILS_ENV=test"
  end

end

task :default => :spec
