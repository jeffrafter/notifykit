class NotificationsController < ::ApplicationController
  before_filter :require_login
  before_filter :require_notification

  helper_method :notification

  layout false

  def recent
    respond_to do |format|
      format.json { render recent_notifications.to_json }
    end
  end

  def view
    respond_to do |format|
      format.html { render text: notification.email_html }
      format.text { render text: notification.email_text }
    end
  end

  def click
    notification.click

    # To prevent a bare redirect, validate that the redirect url
    # was generated when the email was sent
    target_url = params[:r]
    target_url = root_url unless notification.email_urls.split("\n").index(target_url)

    respond_to do |format|
      format.json { head :no_content }
      format.html { redirect_to append_tracking_params(target_url) }
    end
  end

  def read
    notification.read
    respond_with_no_content
  end

  def ignore
    notification.ignore
    respond_with_no_content
  end

  def cancel
    notification.cancel
    respond_with_no_content
  end

  protected

  def require_notification
    notification
  end

  def notification
    return @notification if defined?(@notification)
    @notification = current_user.notifications.where(token: params[:token]).first || raise(ActiveRecord::RecordNotFound)
  end

  def respond_with_no_content
    respond_to do |format|
      format.json { head :no_content }
      format.html {
        data = "GIF89a\001\000\001\000\200\000\000\000\000\000\377\377\377!\371\004\001\000\000\000\000,\000\000\000\000\001\000\001\000\000\002\001D\000;"
        send_data data, :filename => 'blank.gif', :type => 'image/gif', :disposition => 'inline'
      }
    end
  end

  def append_tracking_params(url)
    query = []
    query << request.query_string if request.query_string.present?
    query << "utm_campaign=#{utm_campaign}" unless params[:utm_campaign].present?
    query << "utm_medium=#{utm_medium}" unless params[:utm_medium].present?
    query << "utm_source=#{utm_source}" unless params[:utm_source].present? || utm_source.blank?
    url += (url =~ /\?/) ? "&" : "?"
    url += query.join('&')
  end

  def utm_source
    # TODO insert your company name here or the source of the campaign you would like when the redirect lands
  end

  def utm_campaign
    notification.kind
  end

  def utm_medium
    "notification"
  end
end
