require "spec_helper"

describe NotificationsMailer do
  describe "notify" do
    let(:notification) { create(:notification) }
    let(:mail) { NotificationsMailer.notify(notification.id) }

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
      new_mail = NotificationsMailer.notify(new_notification.id)
      new_mail.body.encoded.should match(new_notification.token)
    end

    it "delivers to the to address" do
      new_mail = NotificationsMailer.notify(notification.id, "another@example.com")
      new_mail.to.should == ["another@example.com"]
    end

    describe "aborts" do
      before(:each) do
        NotificationsMailer.any_instance.stub(:notification).and_return(notification)
      end

      it "aborts the delivery" do
        notification.cancelled_at = Time.now
        mail.class.should == ActionMailer::Base::NullMail
        mail.deliver
        notification.reload
        notification.email_not_sent_at.should_not be_nil
      end

      it "aborts if the notification is cancelled" do
        notification.cancelled_at = Time.now
        NotificationsMailer.any_instance.should_receive(:abort_cancelled)
        mail
      end

      it "aborts if the notification should not be delivered" do
        notification.deliver_via_email = false
        NotificationsMailer.any_instance.should_receive(:abort_do_not_deliver)
        mail
      end

      it "aborts if the notification is already sent" do
        notification.email_sent_at = Time.now
        NotificationsMailer.any_instance.should_receive(:abort_already_sent)
        mail
      end

      it "aborts if the notification there is no recipient" do
        notification.email = nil
        NotificationsMailer.any_instance.should_receive(:abort_no_recipient)
        mail
      end

      it "aborts if the notification if the user is unsubscribed" do
        NotificationsMailer.any_instance.stub(:unsubscribed?).and_return(true)
        NotificationsMailer.any_instance.should_receive(:abort_unsubscribed)
        mail
      end

      it "aborts if the notification if the user is not whitelisted" do
        NotificationsMailer.any_instance.stub(:whitelist_excluded?).and_return(true)
        NotificationsMailer.any_instance.should_receive(:abort_whitelist_excluded)
        mail
      end
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

      it "captures the urls" do
        notification.reload.email_urls.split("\n").index(privacy_url).should_not be_nil
      end

      it "sets the email sent at" do
        notification.reload.email_sent_at.should_not be_nil
      end
    end

    describe "tracking" do
      before(:each) do
        NotificationsMailer.any_instance.stub(:notification).and_return(notification)
      end

      it "appends tracking" do
        mail
        notification.reload.email_text.should_not match(privacy_url)
        notification.email_text.should include(notification_click_url(notification) + "?r=http%3A%2F%2Fexample.com" + CGI.escape(privacy_path))
      end

      it "does not append tracking if the message is marked do not track" do
        notification.do_not_track = true
        mail
        notification.reload.email_text.should match(privacy_url)
      end
    end
  end
end
