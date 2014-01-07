require "notifykit/version"

module Notifykit
  require 'notifykit/engine' if defined?(Rails)

  def self.tracking_pixel
    "GIF89a\001\000\001\000\200\000\000\000\000\000\377\377\377!\371\004\001\000\000\000\000,\000\000\000\000\001\000\001\000\000\002\001D\000;"
  end
end
