class NotificationsMailer < ActionMailer::Base
  helper_method :notification, :append_tracking

  self.mailer_name = 'notifications'

  def notify(notification_id, to=nil)
    to = notification.email if to.blank?

    # Safety checks
    return abort_cancelled if notification.cancelled?
    return abort_already_sent if notification.email_sent_at.present?
    return abort_no_recipient if to.blank?
    return abort_unsubscribed if unsubscribed?(to)
    return abort_whitelist_excluded if white_list_exlcuded?(to)

    options = {
      to: to,
      from: notification.email_from,
      subject: notification.email_subject
    }
    options[:reply_to] = notification.email_reply_to unless notification.email_reply_to.blank?

    message = mail(options) do |format|
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

  def unsubscribed?(to)
    # TODO Utilize unsubscribe logic here, possibly checking notification.kind or notification.user
    false
  end

  def whitelist_excluded?(to)
    # TODO Utilize whitelist logic here to ensure you do not send business emails in development or test
    false
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

  # Return a URL that will track clicks and can be verified later
  def append_tracking(url)
    urls << url
    notification_url(notification, r: url)
  end

  def urls
    @urls ||= []
  end
end
