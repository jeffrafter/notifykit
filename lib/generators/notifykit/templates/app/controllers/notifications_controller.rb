class NotificationsController < ::ApplicationController
  before_filter :require_login
  before_filter :require_notification

  include NotificationsHelper

  helper_method :notification

  layout false

  def recent
    respond_to do |format|
      format.json { render json: recent_notifications.to_json }
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
    target_url = root_url if notification.email_urls.blank? || !notification.email_urls.split("\n").index(target_url)

    respond_to do |format|
      format.json { head :no_content }
      format.html { redirect_to append_tracking_params(target_url) }
    end
  end

  def read
    notification.read
    respond_with_no_content
  end

  def unsubscribe
    notification.unsubscribe

    # TODO you may want to improve the unsubscribe logic here
    respond_to do |format|
      format.json { head :no_content }
      format.html { redirect_to root_url }
    end
  end

  def ignore
    notification.ignore

    respond_to do |format|
      format.json { head :no_content }
      format.html { redirect_to root_url }
    end
  end

  def cancel
    notification.cancel

    respond_to do |format|
      format.json { head :no_content }
      format.html { redirect_to root_url }
    end
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
        send_data Notifykit.tracking_pixel, :filename => 'blank.gif', :type => 'image/gif', :disposition => 'inline'
      }
    end
  end

  def append_tracking_params(url)
    return url if notification.do_not_track
    query = []
    query << "utm_campaign=#{utm_campaign}" unless url =~ /utm_campaign/
    query << "utm_medium=#{utm_medium}" unless url =~ /utm_medium/
    query << "utm_source=#{utm_source}" unless url =~ /utm_source/ || utm_source.blank?
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
