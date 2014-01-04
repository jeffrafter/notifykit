module NotificationsHelper
  def notification_company_name
    # TODO According to CANSPAM you must include company contact information
  end

  def notification_company_address
    # TODO According to CANSPAM you must include company contact information
  end

  def recent_notifications
    return @recent_notifications if defined?(@recent_notifications)
    @recent_notifications = current_user && current_user.notifications.recent.all
  end
end
