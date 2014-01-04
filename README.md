# Notifykit

A gem for installing notification support into you app.

## Why?

More information is available in [FEATURES](FEATURES.md).

## Installation

Add this line to your application's Gemfile:

    group :development do
      gem 'notifykit'
    end

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install notifykit

## Usage

Once you've installed notifykit you can run the generator:

    rails g notifykit:install

This will add some basic migrations for the user:

    create  db/migrate/20140102001051_create_notifications.rb

## Testing

The files generated using the installer include specs. To test these you should be
able to:

    $ bundle install

Then run the default task:

    $ rake

This will run the specs, which by default will generate a new Rails application,
run the installer, and execute the specs in the context of that temporary
application.

The specs that are generated utilize a generous amount of mocking and stubbing in
an attempt to keep them fast. However, they use vanilla `rspec-rails`, meaning
they are not using mocha. The two caveats are shoulda-matchers and FactoryGirl which
are required. It is pretty easy to remove these dependencies, it just turned out
that more people were using them than not.

## TODO

* stubs for tracking
* stubs for domain handling
* notification templates
* subject/title templates
* http://blog.mailgun.com/post/tips-tricks-avoiding-gmail-spam-filtering-when-using-ruby-on-rails-action-mailer/

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
