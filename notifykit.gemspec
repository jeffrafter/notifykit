# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'notifykit/version'

Gem::Specification.new do |spec|
  spec.name          = "notifykit"
  spec.version       = Notifykit::VERSION
  spec.authors       = ["Jeff Rafter"]
  spec.email         = ["jeffrafter@gmail.com"]
  spec.description   = %q{A notification system for your Rails app}
  spec.summary       = %q{Notifykit is a generator that will install a notifications model, mailer, controller and views. It allows tracking clicks, reads and unsubscribing}
  spec.homepage      = "https://github.com/jeffrafter/notifykit"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec-rails"
  spec.add_development_dependency "factory_girl_rails"
end
