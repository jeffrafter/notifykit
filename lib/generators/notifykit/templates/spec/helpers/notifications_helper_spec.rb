# You can replace this with rails_helper for RSpec 3.0
require 'spec_helper'

class HelperWithUser
  include NotificationsHelper

  attr_accessor :current_user

  def initialize(user)
    @current_user = user
  end
end

RSpec.describe NotificationsHelper, type: :helper do
  let(:user) { create(:user) }

  it "returns the company name for use in notifications" do
    # If this is failing it is because you need to add your company name
    # to app/helpers/notifications_helper.rb
    expect(helper.notification_company_name).to_not be_blank
  end

  it "returns the company address for use in notifications" do
    # If this is failing it is because you need to add your company address
    # to app/helpers/notifications_helper.rb
    expect(helper.notification_company_name).to_not be_blank
  end

  it "returns the company logo for use in notifications" do
    # If this is failing it is because you need to add your company logo
    # to app/helpers/notifications_helper.rb
    expect(helper.notification_company_logo).to_not be_blank
  end

  it "finds recent notifications" do
    helper = HelperWithUser.new(user)
    4.times { create(:notification, user: helper.current_user) }
    expect(helper.recent_notifications.count).to eq(3)
  end
end
