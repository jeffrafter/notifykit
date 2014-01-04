ENV["RAILS_ENV"] ||= 'test'
require File.expand_path('../tmp/sample/config/environment', __FILE__)
require 'rspec/rails'
require 'rspec/autorun'

Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

ActiveRecord::Migration.check_pending! if defined?(ActiveRecord::Migration)

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.infer_base_class_for_anonymous_controllers = false
  config.order = "random"
  config.include FactoryGirl::Syntax::Methods

  # Because we are not running things in Rails we need to stub some secrets
  config.before(:each) { Rails.application.config.stub(:secret_token).and_return("SECRET") }
end
