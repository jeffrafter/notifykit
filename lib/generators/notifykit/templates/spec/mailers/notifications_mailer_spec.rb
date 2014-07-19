# You can replace this with rails_helper for RSpec 3.0
require 'spec_helper'

RSpec.describe NotificationsMailer, type: :mailer do
  describe "notify" do
    let(:notification) { create(:notification) }
    let(:mail) { NotificationsMailer.notify(notification.id) }
    let(:user) { create(:user) }

    before(:each) do
      Rails.application.default_url_options[:host] = "http://example.com"
      allow_any_instance_of(Notification).to receive(:subject).and_return(user)
    end

    it "renders the email and uses the notification fields" do
      expect(mail.subject).to eq notification.email_subject
      expect(mail.to).to eq [notification.email]
      expect(mail.from).to eq [notification.email_from]
      expect(mail.body.encoded).to match(notification.token)
    end

    it "has a text part and html part" do
      expect(mail.html_part.body).to match("Hi")
      expect(mail.text_part.body).to match("Hi")
    end

    it "finds the notification" do
      new_notification = create(:notification)
      new_mail = NotificationsMailer.notify(new_notification.id)
      expect(new_mail.body.encoded).to match(new_notification.token)
    end

    it "delivers to the to address" do
      new_mail = NotificationsMailer.notify(notification.id, "another@example.com")
      expect(new_mail.to).to eq ["another@example.com"]
    end

    describe "aborts" do
      before(:each) do
        allow_any_instance_of(NotificationsMailer).to receive(:notification).and_return(notification)
      end

      it "aborts the delivery" do
        notification.cancelled_at = Time.now
        expect(mail.class).to eq ActionMailer::Base::NullMail
        mail.deliver
        notification.reload
        expect(notification.email_not_sent_at).to_not be_nil
      end

      it "aborts the notification if it is cancelled" do
        notification.cancelled_at = Time.now
        expect_any_instance_of(NotificationsMailer).to receive(:abort_cancelled)
        mail
      end

      it "aborts the notification if it should not be delivered" do
        notification.deliver_via_email = false
        expect_any_instance_of(NotificationsMailer).to receive(:abort_do_not_deliver)
        mail
      end

      it "aborts the notification if has been already sent" do
        notification.email_sent_at = Time.now
        expect_any_instance_of(NotificationsMailer).to receive(:abort_already_sent)
        mail
      end

      it "aborts the notification if there is no recipient" do
        notification.email = nil
        expect_any_instance_of(NotificationsMailer).to receive(:abort_no_recipient)
        mail
      end

      it "aborts the notification if the user is unsubscribed" do
        allow_any_instance_of(NotificationsMailer).to receive(:unsubscribed?).and_return(true)
        expect_any_instance_of(NotificationsMailer).to receive(:abort_unsubscribed)
        mail
      end

      it "aborts if the notification if the user is not whitelisted" do
        allow_any_instance_of(NotificationsMailer).to receive(:whitelist_excluded?).and_return(true)
        expect_any_instance_of(NotificationsMailer).to receive(:abort_whitelist_excluded)
        mail
      end
    end

    describe "captures" do
      before(:each) do
        mail
      end

      it "captures the html part" do
        expect(notification.reload.email_html).to match("Hi")
      end

      it "captures the text part" do
        expect(notification.reload.email_text).to match("Hi")
      end

      it "captures the urls" do
        expect(notification.reload.email_urls.split("\n").index(privacy_url)).to_not be_nil
      end

      it "sets the email sent at" do
        expect(notification.reload.email_sent_at).to_not be_nil
      end
    end

    describe "tracking" do
      before(:each) do
        allow_any_instance_of(NotificationsMailer).to receive(:notification).and_return(notification)
      end

      it "appends tracking" do
        mail
        expect(notification.reload.email_text).to_not match(privacy_url)
        expect(notification.email_text).to include(notification_click_url(notification) + "?r=http%3A%2F%2Fexample.com" + CGI.escape(privacy_path))
      end

      it "does not append tracking if the message is marked do not track" do
        notification.do_not_track = true
        mail
        expect(notification.reload.email_text).to match(privacy_url)
      end
    end

    describe "layouts" do
      it "uses the default layout" do
        expect_any_instance_of(NotificationsMailer).to receive(:render).with({layout: nil}).twice
        mail
      end

      it "does not use the default layout" do
        notification.use_default_layout = false
        notification.save
        expect_any_instance_of(NotificationsMailer).to receive(:render).with({layout: false}).twice
        mail
      end
    end
  end
end

