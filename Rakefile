require "bundler/gem_tasks"
require 'rspec/core/rake_task'

gem_name = :notifykit

RSpec::Core::RakeTask.new(spec: ["generator:cleanup", "generator:prepare", "generator:#{gem_name}"]) do |task|
  task.pattern = "spec/**/*_spec.rb"
  task.rspec_opts = "--color --drb"
  task.verbose = true
end

namespace :spec do
  RSpec::Core::RakeTask.new(database: ["generator:cleanup", "generator:prepare", "generator:database", "generator:#{gem_name}"]) do |task|
    task.pattern = "spec/**/*_spec.rb"
    task.verbose = true
  end
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

    system "cd spec/tmp && rails new sample"

    # bundle
    gem_root = File.expand_path(File.dirname(__FILE__))
    system "echo \"gem 'rspec-rails'\" >> spec/tmp/sample/Gemfile"
    system "echo \"gem '#{gem_name}', :path => '#{gem_root}'\" >> spec/tmp/sample/Gemfile"
    system "cd spec/tmp/sample && bundle install"
    system "cd spec/tmp/sample && rails g rspec:install"

    # Make a thing
    system "cd spec/tmp/sample && rails g scaffold thing name:string mood:string"
  end

  # This task is not used unless you need to test the generator with an alternate database
  # such as mysql or postgres. By default the sample application utilize sqlite3
  desc "Prepares the application with an alternate database"
  task :database do
    puts "==  Configuring the database =================================================="
    system "cp config/database.yml.example spec/tmp/sample/config/database.yml"
    system "cd spec/tmp/sample && rake db:migrate:reset"
  end

  desc "Run the #{gem_name} generator"
  task gem_name do
    system "cd spec/tmp/sample && rails g #{gem_name}:install --force && rake db:migrate db:test:prepare"
  end

end

task :default => :spec
