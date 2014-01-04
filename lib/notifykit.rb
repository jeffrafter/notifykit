require "notifykit/version"
require 'notifykit/abortable_mailer'

module Notifykit
  require 'notifykit/engine' if defined?(Rails)
end
