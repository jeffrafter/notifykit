module NotificationsHelper
  def notification_company_name
    # TODO According to CANSPAM you must include company contact information
    <% if options.test_mode? %>"Test Company"<% end %>
  end

  def notification_company_address
    # TODO According to CANSPAM you must include company contact information
    <% if options.test_mode? %>"Test Company Address"<% end %>
  end

  def recent_notifications
    return @recent_notifications if defined?(@recent_notifications)
    @recent_notifications = current_user && current_user.notifications.recent
  end
end
