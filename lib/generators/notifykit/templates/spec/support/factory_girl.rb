 # FactoryGirl allows you to quickly create template based objects
# The syntax methods give you inline `create` and a `build` commands
RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
end
