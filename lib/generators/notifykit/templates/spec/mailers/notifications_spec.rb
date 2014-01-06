require "spec_helper"

describe Notifications do
  describe "notify" do
    let(:notification) { create(:notification) }
    let(:mail) { Notifications.notify(notification.id) }

    before(:each) do
      Rails.application.default_url_options[:host] = "http://example.com"
      user = User.new(:first_name => 'Test')
      Notification.any_instance.stub(:subject).and_return(user)
    end

    it "renders the email and uses the notification fields" do
      mail.subject.should == notification.email_subject
      mail.to.should == [notification.email]
      mail.from.should == [notification.email_from]
      mail.body.encoded.should match(notification.token)
    end

    it "has a text part and html part" do
      mail.html_part.body.should match("Hi")
      mail.text_part.body.should match("Hi")
    end

    it "finds the notification" do
      new_notification = create(:notification)
      new_mail = Notifications.notify(new_notification.id)
      new_mail.body.encoded.should match(new_notification.token)
    end

    it "delivers to the to address" do
      new_mail = Notifications.notify(notification.id, "another@example.com")
      new_mail.to.should == ["another@example.com"]
    end

    describe "aborts" do
      before(:each) do
        Notifications.any_instance.stub(:notification).and_return(notification)
      end

      it "aborts the delivery" do
        notification.cancelled_at = Time.now
        mail.class.should == AbortableMailer::UndeliverableMailMessage
        notification.reload
        notification.email_not_sent_at.should_not be_nil
      end

      it "aborts if the notification is cancelled" do
        notification.cancelled_at = Time.now
        Notifications.any_instance.should_receive(:abort_cancelled)
        mail
      end

      it "aborts if the notification should not be delivered"
      it "aborts if the notification is already sent"
      it "aborts if the notification there is no recipient"
      it "aborts if the notification if the user is unsubscribed"
      it "aborts if the notification if the user is not whitelisted"
    end

    describe "captures" do
      before(:each) do
        mail
      end

      it "captures the html part" do
        notification.reload.email_html.should match("Hi")
      end

      it "captures the text part" do
        notification.reload.email_text.should match("Hi")
      end

      it "captures the urls"
      it "sets the email sent at"
    end

    it "appends tracking"
    it "does not append tracking if the message is marked do not track"
  end
end
