require 'spec_helper'

describe NotificationsHelper do
  let(:user) { User.create(email: "test@example.com"); User.first }

  it "returns the company name for use in notifications" do
    # If this is failing it is because you need to add your company name
    # to app/helpers/notifications_helper.rb
    helper.notification_company_name.should_not be_blank
  end

  it "returns the company address for use in notifications" do
    # If this is failing it is because you need to add your company address
    # to app/helpers/notifications_helper.rb
    helper.notification_company_name.should_not be_blank
  end

  it "returns the company logo for use in notifications" do
    # If this is failing it is because you need to add your company logo
    # to app/helpers/notifications_helper.rb
    helper.notification_company_logo.should_not be_blank
  end

  it "finds recent notifications" do
    helper.stub(:current_user).and_return(user)
    4.times { create(:notification, user: user) }
    helper.recent_notifications.count.should == 3
  end
end
