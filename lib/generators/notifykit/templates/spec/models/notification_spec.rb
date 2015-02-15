require 'rails_helper'

<% if options.test_mode? %>
ENV['EMAIL_FROM'] = "YOUR DEFAULT FROM ADDRESS"
<% end %>

RSpec.describe Notification, type: :model do
  let(:notification) { build(:notification) }
  let(:user) { create(:user, first_name: 'Test') }

  it { should belong_to(:user) }

  it "uses the token as the param" do
    notification.save
    expect(notification.to_param).to eq(notification.token)
  end

  describe "recent" do
    it "finds recent notifications (max of 3)" do
      4.times { create(:notification) }
      expect(Notification.recent.count).to eq(3)
    end

    it "does not find read notifications" do
      notification.save
      create(:notification, read_at: Time.now)
      expect(Notification.recent).to eq [notification]
    end

    it "does not find cancelled notifications" do
      notification.save
      create(:notification, cancelled_at: Time.now)
      expect(Notification.recent).to eq [notification]
    end
  end

  describe "validations" do
    it "validates email if delivering via email" do
      allow(notification).to receive(:set_email)
      notification.email = nil
      expect(notification).to_not be_valid
      notification.email = user.email
      expect(notification).to be_valid
    end

    it "defaults email_from if delivering via email" do
      notification.email_from = nil
      expect(notification).to be_valid
      expect(notification.email_from).to eq("YOUR DEFAULT FROM ADDRESS")
    end

    it "validates email_subject if delivering via email" do
      notification.email_subject = nil
      expect(notification).to_not be_valid
      notification.email_subject = "Welcome to the application"
      expect(notification).to be_valid
    end

    it "does not validate email if not delivering via email" do
      notification.deliver_via_email = false
      notification.email = nil
      expect(notification).to be_valid
    end

    it "does not validate email_subject if not delivering via email" do
      notification.deliver_via_email = false
      notification.email_from = nil
      expect(notification).to be_valid
    end

    it "does not validate email_subject if not delivering via email" do
      notification.deliver_via_email = false
      notification.email_subject = nil
      expect(notification).to be_valid
    end
  end

  it "should be clickable" do
    expect(notification.click).to eq(true)
    expect(notification.clicked_at).to_not be_nil
  end

  it "should count the clicks" do
    expect {
      expect(notification.click).to eq(true)
    }.to change(notification, :click_count)
  end

  it "should not be clickable if cancelled" do
    notification.cancelled_at = Time.now
    expect(notification.click).to eq(false)
    expect(notification.clicked_at).to be_nil
  end

  it "should be readable" do
    expect(notification.read).to eq(true)
    expect(notification.read_at).to_not be_nil
  end

  it "should count the reads" do
    expect {
      expect(notification.read).to eq(true)
    }.to change(notification, :read_count)
  end

  it "should not be readable if cancelled" do
    notification.cancelled_at = Time.now
    expect(notification.read).to eq(false)
    expect(notification.read_at).to be_nil
  end

  it "should be ignorable" do
    expect(notification.ignore).to eq(true)
    expect(notification.ignored_at).to_not be_nil
  end

  it "should not be ignorable if cancelled" do
    notification.cancelled_at = Time.now
    expect(notification.ignore).to eq(false)
    expect(notification.ignored_at).to be_nil
  end

  it "should be cancellable" do
    expect(notification.cancel).to eq(true)
    expect(notification.cancelled_at).to_not be_nil
  end

  it "should not be cancellable if cancelled" do
    cancel_time = 1.day.ago
    notification.cancelled_at = cancel_time
    expect(notification.cancel).to eq(true)
    expect(notification.cancelled_at).to eq(cancel_time)
  end

  it "should be cancelled" do
    expect(notification).to_not be_cancelled
    notification.cancelled_at = Time.now
    expect(notification).to be_cancelled
  end

  describe "unsubscribe" do
    it "sets unsubscribed_at" do
      expect(notification.unsubscribe).to eq(true)
      expect(notification.unsubscribed_at).to_not be_nil
    end
  end

  describe "subject" do
    it "has a subject" do
      user = create(:user)
      notification.subject_type = "User"
      notification.subject_id = user.id
      expect(notification.subject.id).to eq(user.id)
    end
  end

  describe "delivering" do
    before(:each) do
      notification.save
    end

    # This spec tests through the full integration
    it "should deliver the notification" do
      Rails.application.default_url_options[:host] = "http://example.com"
      allow_any_instance_of(Notification).to receive(:subject).and_return(user)
      expect_any_instance_of(Mail::Message).to receive(:deliver)
      notification.deliver
    end

    it "should not deliver if it has already been delivered" do
      expect(NotificationsMailer).to_not receive(:notify)
      notification.email_sent_at = Time.now
      notification.deliver
    end

    it "should not deliver unless it is delivering via email" do
      expect(NotificationsMailer).to_not receive(:notify)
      notification.deliver_via_email = false
      notification.deliver
    end
  end

  it "should set the email" do
    notification.email = nil
    notification.user = user
    notification.valid?
    expect(notification.email).to eq(user.email)
  end

  it "should not set the email unless it is delivering via email" do
    notification.email = nil
    notification.user = user
    notification.deliver_via_email = false
    notification.valid?
    expect(notification.email).to be_nil
  end

  it "should set the token" do
    notification.token = nil
    notification.valid?
    expect(notification.token).to_not be_nil
  end
end

