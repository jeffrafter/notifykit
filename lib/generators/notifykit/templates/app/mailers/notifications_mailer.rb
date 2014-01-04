require 'action_mailer'

module Notifykit
  class NotificationsMailer < ActionMailer::Base
    before_filter :append_view_paths

    helper_method :notification, :trackable

    self.mailer_name = 'notifications'

    def notify(notification_id, to=nil)
      to = notification.email if to.blank?

      # Safety checks
      return abort_cancelled if notification.cancelled?
      return abort_already_sent if notification.email_sent_at.present?
      return abort_no_recipient if to.blank?
      return abort_unsubscribed if unsubscribed?
      return abort_whitelist_excluded if white_list_exlcuded?

      message = mail(:to => to,
           :from => notification.from,
           :subject => notification.title) do |format|
        format.html { render "#{mailer_name}/mailer" }
        format.text { render "#{mailer_name}/mailer" }
      end

      # Storing the rendered template might be a bit aggressive if you are
      # sending large batches of emails.
      notification.email_html = message.html_part
      notification.email_text = message.text_part
      notification.email_sent_at = Time.now
      notification.urls = urls.join("\n")
      notification.save

      message
    end

    protected

    def notification
      return @notification if defined?(@notification)
      @notification = Notification.find(notification_id)
    end

    def unsubscribed?
      # TODO
    end

    def whitelist_excluded?
      # TODO Whitelist.exclude?(@recipient) && !Rails.env.test?
    end

    def abort_delivery(reason)
      if notification.email_not_sent_at.blank?
        notification.email_not_sent_reason = reason
        notification.email_not_sent_at = Time.now
        notification.save
      end
      super(reason)
    end

    def abort_cancelled
      abort_delivery("cancelled")
    end

    def abort_already_sent
      abort_delivery("already sent")
    end

    def abort_no_recipient
      abort_delivery("no recipient address")
    end

    def abort_unsubscribed
      abort_delivery("recipient unsubscribed")
    end

    def abort_whitelist_excluded
      abort_delivery("recipient not on whitelist")
    end

    def trackable(url)
      urls << url
      # Return a clickable url that can be verified
      notification_url(notification, r: url)
    end

    def urls
      @urls ||= []
    end

    def append_view_paths
      append_view_path Pathname.new(File.expand_path('../../../', __FILE__)).join('lib', 'generators', 'notifykit', 'templates', 'app', 'views')
    end
  end
end