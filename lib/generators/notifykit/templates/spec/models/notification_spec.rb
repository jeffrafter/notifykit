require 'spec_helper'

describe Notification do

  let(:notification) { build(:notification) }

  it { should belong_to(:user) }

  describe "recent" do
    it "finds recent notifications" do
      4.times { create(:notification) }
      Notification.recent.count.should == 3
    end

    it "does not find read notifications" do
      notification.save
      create(:notification, read_at: Time.now)
      Notification.recent.should == [notification]
    end

    it "does not find cancelled notifications" do
      notification.save
      create(:notification, cancelled_at: Time.now)
      Notification.recent.should == [notification]
    end
  end

  describe "validations" do
    it "validates email if delivering via email" do
      notification.stub(:set_email)
      notification.email = nil
      notification.should_not be_valid
      notification.email = "test@example.com"
      notification.should be_valid
    end

    it "validates email_from if delivering via email" do
      notification.email_from = nil
      notification.should_not be_valid
      notification.email_from = "Welcome to the application"
      notification.should be_valid
    end

    it "validates email_subject if delivering via email" do
      notification.email_subject = nil
      notification.should_not be_valid
      notification.email_subject = "Welcome to the application"
      notification.should be_valid
    end

    it "does not validate email if not delivering via email" do
      notification.deliver_via_email = false
      notification.email = nil
      notification.should be_valid
    end

    it "does not validate email_subject if not delivering via email" do
      notification.deliver_via_email = false
      notification.email_from = nil
      notification.should be_valid
    end

    it "does not validate email_subject if not delivering via email" do
      notification.deliver_via_email = false
      notification.email_subject = nil
      notification.should be_valid
    end
  end

  it "should be clickable" do
    notification.click.should == true
    notification.clicked_at.should_not be_nil
  end

  it "should count the clicks" do
    expect {
      notification.click.should == true
    }.to change(notification, :click_count)
  end

  it "should not be clickable if cancelled" do
    notification.cancelled_at = Time.now
    notification.click.should == false
    notification.clicked_at.should be_nil
  end

  it "should be readable" do
    notification.read.should == true
    notification.read_at.should_not be_nil
  end

  it "should count the reads" do
    expect {
      notification.read.should == true
    }.to change(notification, :read_count)
  end

  it "should not be readable if cancelled" do
    notification.cancelled_at = Time.now
    notification.read.should == false
    notification.read_at.should be_nil
  end

  it "should be ignorable" do
    notification.ignore.should == true
    notification.ignored_at.should_not be_nil
  end

  it "should not be ignorable if cancelled" do
    notification.cancelled_at = Time.now
    notification.ignore.should == false
    notification.ignored_at.should be_nil
  end

  it "should be cancellable" do
    notification.cancel.should == true
    notification.cancelled_at.should_not be_nil
  end

  it "should not be cancellable if cancelled" do
    cancel_time = 1.day.ago
    notification.cancelled_at = cancel_time
    notification.cancel.should == true
    notification.cancelled_at.should == cancel_time
  end

  it "should be cancelled" do
    notification.should_not be_cancelled
    notification.cancelled_at = Time.now
    notification.should be_cancelled
  end

  it "should be unsubscribable" do
    notification.unsubscribe.should == true
    notification.unsubscribed_at.should_not be_nil
  end

  describe "subject" do
    it "has a subject" do
      Thing.create
      thing = Thing.first
      notification.subject_type = "Thing"
      notification.subject_id = thing.id
      notification.subject.id.should == thing.id
    end
  end

  describe "delivering" do
    before(:each) do
      notification.save
    end

    # This spec tests through the full integration
    it "should deliver the notification" do
      Rails.application.default_url_options[:host] = "http://example.com"
      user = User.new(:first_name => 'Test')
      Notification.any_instance.stub(:subject).and_return(user)
      Mail::Message.any_instance.should_receive(:deliver)
      notification.deliver
    end

    it "should not deliver if it has already been delivered" do
      Notifications.should_not_receive(:notify)
      notification.email_sent_at = Time.now
      notification.deliver
    end

    it "should not deliver unless it is delivering via email" do
      Notifications.should_not_receive(:notify)
      notification.deliver_via_email = false
      notification.deliver
    end
  end

  it "should set the email" do
    user = User.new(email: "test@example.com")
    notification.email = nil
    notification.user = user
    notification.valid?
    notification.email.should == user.email
  end

  it "should not set the email unless it is delivering via email" do
    user = User.new(email: "test@example.com")
    notification.email = nil
    notification.user = user
    notification.deliver_via_email = false
    notification.valid?
    notification.email.should be_nil
  end

  it "should set the token" do
    notification.token = nil
    notification.valid?
    notification.token.should_not be_nil
  end
end
