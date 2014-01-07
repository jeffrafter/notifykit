# Notifykit

A gem for installing notification support into you app.

## Why?

Most applications need to send emails. In many cases these emails are purely
transactional: email confirmation email, reset password email, etc. In some
cases, however the emails are promotional: weekly product updates,
newsletters, welcome emails. In all cases, understanding how your users
respond to and interact with emails is important and the only way to
do this is to track the emails.

Several email providers give you the ability to track interactions either
on their site or through callbacks. This can make switching email
providers difficult, or in some cases can make integrating your email
statistics into your overall metrics difficult.

Beyond simple tracking, you may want to deliver notifications through
multiple channels. You might want users to be able to view the same
notifications on the site and in their email and track the read
state between them.

Notifykit attempts to address these problems by allowing ever email
to be tracked (read, click, unsubscribe) and gives you additional
features for rendering emails in the browser.

## Will it scale?

Probably not.

This is not the kit you should use if you plan on sending 100K emails per
day. By default, every notification you send will have a corresponding
Notification record. By itself that is a large burden, but it gets
worse. The notification must be created prior to emailing and once
emailed it is updated with the rendered text and HTML. Any interaction with
the notification will create additional database operations.

Even with a modest amount of emails (1000/day) the database would grow
by 10M.day. This can easily overwhelm a small system.

It is possible to change how rendered email messages are stored. For
instance you could change to a strategy where only the needed data
is stored (or even just the `subject_id` and `subject_type`) and
regenerate the rendered text on demand. While this will greatly
decrease the amount of storage, it also means that clicking the
"View Email" link in the email might not show the same content that
was originally sent to the user.

Even with changes to the storage, using a system which generates a
database record for every email will introduce scaling problems.
Larger email systems track emails in a variety of ways and generate
emails in batches (generally avoiding ERB for templates and using
something more like regex replacement).

## Features

More information is available in [FEATURES](FEATURES.md).

* Notifications migration
* Notification model for tracking notification creation in the database
* Notification controller for responding to email and notification interaction
* Notifications mailer for sending `Notification` instances as emails
* Notification helper supporting the mailer and controller
* Mailer layout
* Specs
* Sample welcome template
* Do not track support
* Unsubscribe support
* White-list support for non-production environments
* CANSPAM compliance

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

Once you've installed Notifykit you can run the generator:

    rails g notifykit:install

This will add some basic migrations for the user:

    create  db/migrate/20140102001051_create_notifications.rb

Make sure you migrate the database:

    rake db:migrate

## Requirements

Once you have generated the files from Notifykit you need to do some more
work. First, you need to ensure that you have the user specific methods:

* `require_login`
* `current_user`

If these aren't available in your controllers you'll need to add them or
modify `NotificationsController` and `notifications_controller_spec.rb`. If you
need to add these, you can use
[Authkit](https://github.com/jeffrafter/authkit) which provides these methods.

If your application doesn't have a concept of users you can remove this
dependency (you would also need to change the `CreateNotifications` migration,
the notification lookup in `NotificationsController` and the `set_email`
method in the `Notification` model).

Notifykit also makes some assumptions about your routes. It assumes you have
the following routes:

* `privacy_url`
* `terms_url`
* `help_url`

These are used in the `notify.html.erb` and `notify.text.erb` templates.
Including links to these URLs in your templates is not required, just
helpful.

According to [CAN-SPAM](http://www.business.ftc.gov/documents/bus61-can-spam-act-compliance-guide-business)
you must include your company name and physical address in promotional
emails. By default, Notifykit includes this information on every email (even
for notifications not marked as promotional). Your company logo is also
included. You can change all three of these in the `NotificationsHelper`:

* `notification_company_name`
* `notification_company_address`
* `notification_company_logo`

Note: until you change these the generated specs will fail.

By default, Notifykit assumes that redirected links clicked in your email
should have tracking parameters appended. It sets the `utm_medium`,
`utm_campaign` and `utm_source` parameters (which are useful for Google
Analytics). The `utm_source` is blank by default and can be changed in
the `NotificationsController` in:

* `utm_source`

You can just use your company name here or leave it blank.

## Handling unsubscribes and whitelisting

Currently, the unsubscribe and whitelisting logic is empty. Placeholders
have been left for this functionality and tracking for these features
is included. In the `NotificationsMailer` class there are two methods that
you will need to implement if you want this functionality:

* unsubscribed?
* white_list_excluded?

And in the `NotificationsController` there is an action defined for
handling unsubscribe requests.

Note that only emails marked as `promotional` are given an unsubscribe
link. You may want to change this, or you may want to setup a more
specific notification settings page that is specific to your application.
Given this you could easily build unsubscribe logic for specific
kinds or categories of email.

## Notification fields

General management and delivery:

* `token` - a unique token is generated for every notification record
* `kind` - the notification kind is used for finding template partials and for grouping.
* `category` - not currently used, can be used by the application for grouping multiple kinds of emails together for reporting.
* `promotional` - indicates whether the notification is promotional in nature. If so, an unsubscribe link is included in the footer of the email, default: false
* `transactional` - indicates whether the email is transactional in nature. Not currently used. default: true
* `do_not_track` - if true, no tracking pixel will be placed in the HTML email and click tracking will not be embedded in links. default: false
* `deliver_via_site` - indicates whether or not the notification should be displayed on the site, default: true
* `deliver_via_email` - indicates whether or not the notification should be delivered to the user's email, default: true

Relations:

* `user_id` - the user for this notification
* `subject_id` - any related resource for this notification can be specified by the id and type (this can be accessed via the `subject` and `subject=` methods. Note: this is not the `email_subject`
* `subject_type` - the class of the related resource

Tracking:

* `read_at` - when the notification was first read
* `clicked_at` - when the notification (or a link in the notification) was first clicked
* `ignored_at` - when the notification was marked as ignored
* `cancelled_at` - when the notification was cancelled
* `unsubscribed_at` - if the notification generated an unsubscribe request, this flag is set
* `click_count - how many clicks have occurred for this notification
* `read_count - how many times this notification has been read

Email specific fields:

* `email` - the destination email address
* `email_sent_at` - when the notification was sent as an email
* `email_marked_as_spam_at` - when the email was marked as spam (or a spam report was received). Not currently implemented.
* `email_returned_at` - when the email was returned (or a return report was received). Not currently implemented.
* `email_not_sent_at` - when the email delivery was aborted (if applicable)
* `email_not_sent_reason` - the reason the email delivery was aborted (if applicable)
* `email_reply_to` - the reply to field for the email
* `email_from` - the from field for the email
* `email_subject` - the subject field for the email (this is not the notification subject)
* `email_urls` - any urls for which tracking is added are recorded to protect against malicious redirects
* `email_text` - the rendered text of the email
* `email_html` - the rendered HTML of the email

Unused:

* `data` - stored data used to generate the rendered templates. Not currently used.

## Mail in development

Sending email in development tends to be a challenge. You can use the
Gmail SMTP to send actual emails and view them in your mail client of
choice. In your `config/environments/development.rb` change the following:

    config.action_mailer.default_url_options = { host: "http://localhost:3000" }
    config.action_mailer.raise_delivery_errors = true
    config.action_mailer.perform_deliveries = true

    email_config = YAML::load(File.open("#{Rails.root.to_s}/config/email.yml"))
    config.action_mailer.smtp_settings = email_configRails.env] unless email_config[Rails.env].nil?

Then add a new file called `config/email.yml` with these settings:

    development:
      :address: smtp.gmail.com
      :port: 587
      :authentication: plain
      :user_name: YOUR_GOOGLE_EMAIL
      :password: APP_SPECIFIC_PASSWORD
      :enable_starttls_auto: true

You can obtain an application specific password on the [Google Account Security](https://accounts.google.com/b/0/IssuedAuthSubTokens?hl=en&hide_authsub=1)
page. Make sure you restart Rails when you change this file.

If you just want to be able to view the emails, a much better solution is the
[mailcatcher](https://github.com/sj26/mailcatcher) gem. Change your `smtp_settings`
to:

    config.action_mailer.smtp_settings = { :address => "localhost", :port => 1025, :domain => "localhost:3000" }

From the terminal run:

    $ mailcatcher

This will start the Mailcatcher daemon. Now any emails sent from development will
be trapped by Mailcatcher and you can view the results in your browser at
[http://localhost:1080](http://localhost:1080).

## Creating notification templates and kinds

To send a notification you simply create a new record and call deliver:

    Notification.create(
      user: current_user,
      email_subject: "Welcome to my application",
      email_from: "hello@example.com",
      kind: "welcome").deliver

This will generate a new record in the notifications table, then use
the `NotificationsMailer` to deliver the message. It assumes that you
have `_welcome.html.erb` and `_welcome.text.erb` templates in the
`app/views/notifications` folder. The name of the partial corresponds
to the email kind.

### Customizing the mailer

While this method will work for all of your notifications, you could
also build a wrapper mailer. This can improve your organization if your
mailer needs to do a lot of work to build the email.

For example, you could build a `WelcomeMailer`:

    class WelcomeMailer < NotificationsMailer
      def notify(user_id)
        user = User.find(user_id)

        @notification = Notification.create(
          user: user,
          subject_id: user.id,
          subject_type: "User",
          email_from: "hello@example.com",
          email_subject: "Welcome welcome welcome",
          kind: "welcome")

        super(nil)
      end
    end

The mailer descends from the `NotificationsMailer` giving you access to
the notify method. You can override the method to add your own
behavior (in this case creating a notification as part of the mail
generation) and then call `super`. Notice that we set `@notification`
instance variable and called `super` with `nil`. This saves a database
lookup by `id`.

When Rails searches for templates it will search first in the
`app/views/welcome_mailer` folder and then in the `app/views/notifications_mailer`
folder. Because of this you can create a specific template by adding
new `notify.html.erb` and `notify.text.erb` to your mailer specific
view folder.

### Multiple mailer methods and template names

You may not want to use the method or template name "notify". You can
customize the mailer even further and use your own template name. For
example:

    class WelcomeMailer < NotificationsMailer
      def welcome(user_id)
        user = User.find(user_id)

        @notification = Notification.create(
          user: user,
          subject_id: user.id,
          subject_type: "User",
          email_from: "hello@example.com",
          email_subject: "Welcome welcome welcome",
          kind: "welcome")

        notify(nil)
      end
    end

Here our mailer method is `welcome` instead of overriding `notify`. At
the end of the method, instead of calling `super`, we call `notify`.
When Rails attempts to find the template it will look for a template
named `welcome.html.erb` instead of `notify.html.erb`.

Within your `welcome.html.erb` you can do whatever you like. If you
want to leverage the existing template you can even call render
directly:

    <%= render template: "notifications_mailer/notify" %>

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

## What's missing

* Site notification templates
* Unsubscribing
* Whitelisting
* Do not store rendered templates mode
* Non ERB notification templates
* Subject/title templates
* Redelivering
* Track spam/undeliverable
* Message receipts (envelopes/from/sender)
* http://blog.mailgun.com/post/tips-tricks-avoiding-gmail-spam-filtering-when-using-ruby-on-rails-action-mailer/

Currently the "subject" resource does not track the version. In the future it
might be useful (although it is possible to base the version on the created_at
of the notification). Knowing the version would allow you to re-render templates
based on the object at the time of original notification.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
