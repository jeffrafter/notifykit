require 'action_mailer'

class Notifications < ActionMailer::Base
  helper_method :notification, :append_tracking

  def notify(notification_id, to=nil)
    # Ensure that the notification exists
    self.notification(notification_id)

    to = notification.email if to.blank?

    # Safety checks
    return abort_cancelled if notification.cancelled?
    return abort_do_not_deliver if !notification.deliver_via_email?
    return abort_already_sent if notification.email_sent_at.present?
    return abort_no_recipient if to.blank?
    return abort_unsubscribed if unsubscribed?(to)
    return abort_whitelist_excluded if whitelist_excluded?(to)

    options = {
      to: to,
      from: notification.email_from,
      subject: notification.email_subject
    }
    options[:reply_to] = notification.email_reply_to if notification.email_reply_to.present?

    message = mail(options) do |format|
      format.html
      format.text
    end

    # Storing the rendered template might be a bit aggressive if you are
    # sending large batches of emails.
    notification.email_html = message.html_part.body.to_s
    notification.email_text = message.text_part.body.to_s
    notification.email_sent_at = Time.now
    notification.email_urls = urls.uniq.join("\n")
    notification.save

    message
  end

  protected

  def notification(notification_id=nil)
    return @notification if defined?(@notification)
    @notification = Notification.find(notification_id) if notification_id.present?
    @notification || raise(ActiveRecord::RecordNotFound)
  end

  def unsubscribed?(to)
    # TODO You can implement logic to ensure that the user (or to email) is not unsubscribed
  end

  def whitelist_excluded?(to)
    # TODO You can implement logic to ensure that business emails are not sent in development or test environments
  end

  def abort_delivery(reason)
    if notification.email_not_sent_at.blank?
      notification.email_not_sent_reason = reason
      notification.email_not_sent_at = Time.now
      notification.save
    end
    NullMail.new
  end

  def abort_cancelled
    abort_delivery("cancelled")
  end

  def abort_do_not_deliver
    abort_delivery("do not deliver via email")
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

  # Return a URL that tracks clicks and that can be verified
  def append_tracking(url)
    urls << url
    return url if notification.do_not_track?
    notification_click_url(notification, r: url)
  end

  def urls
    @urls ||= []
  end
end
