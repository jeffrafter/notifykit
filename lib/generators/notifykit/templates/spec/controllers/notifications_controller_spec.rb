require 'spec_helper'

<% if options.test_mode? %>
  module RequireLogin
    def require_login
      redirect_to root_path unless current_user
    end
  end

  NotificationsController.send(:include, RequireLogin)
<% end %>

describe NotificationsController do

  let(:user) { User.create(email: "test@example.com"); User.first }
  let(:notification) { build(:notification, token: "TOKEN", user: user) }
  let(:valid_params) { { token: notification.token } }

  # Require login is assumed to be a method on your ApplicationController
  # it might have been created by Authkit.
  describe "requires login" do
    before(:each) do
      controller.stub(:notification).and_return(notification)
    end

    it "redirects the if there is no user" do
      controller.stub(:current_user).and_return(nil)
      get :read, valid_params
      response.should be_redirect
    end

    it "returns success if there is a user" do
      controller.stub(:current_user).and_return(user)
      get :read, valid_params
      response.should be_success
    end
  end

  describe "requires notification" do
    before(:each) do
      controller.stub(:current_user).and_return(user)
    end

    it "raises a RecordNotFound if it can't find the notification" do
      expect {
        get :read, valid_params
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "doesn't find a notification belonging to another user" do
      expect {
        notification.user = User.create(email: "another@example.com")
        notification.save
        get :read, valid_params
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "returns success if there is a notification" do
      expect {
        notification.save
        get :read, valid_params
        response.should be_success
      }.not_to raise_error
    end
  end

  describe "GET" do
    before(:each) do
      controller.stub(:current_user).and_return(user)
      controller.stub(:notification).and_return(notification)
    end

    describe "recent" do
      it "should find recent notifications via json" do
        get :recent, { format: 'json' }
        response.should be_success
      end
    end

    describe "view" do
      it "should view the html" do
        notification.email_html = "SOME HTML"
        get :view, valid_params
        response.should be_success
        response.body.should == "SOME HTML"
      end

      it "should view the text" do
        notification.email_text = "SOME TEXT"
        get :view, valid_params.merge(format: 'text')
        response.should be_success
        response.body.should == "SOME TEXT"
      end
    end

    describe "click" do
      it "should click and redirect" do
        target_url = "http://example.com"
        notification.should_receive(:click)
        notification.email_urls = target_url
        get :click, valid_params.merge(r: target_url)
        response.should be_redirect
        response.should redirect_to(target_url+"?utm_campaign=welcome&utm_medium=notification")
      end

      it "should not redirect to unknown urls" do
        target_url = "http://example.com"
        notification.should_receive(:click)
        get :click, valid_params.merge(r: target_url)
        response.should be_redirect
        response.should redirect_to(root_path+"?utm_campaign=welcome&utm_medium=notification")
      end

      it "should click via json" do
        notification.should_receive(:click)
        get :click, valid_params.merge(format: 'json')
        response.should be_success
      end
    end

    describe "read" do
      it "should mark the notification as read" do
        notification.should_receive(:read)
        get :read, valid_params
        response.should be_success
      end
    end

    describe "unsubscribe" do
      it "should mark the notification as unsubscribed" do
        notification.should_receive(:unsubscribe)
        get :unsubscribe, valid_params
        response.should be_redirect
      end

      it "should mark the notification as unsubscribed via json" do
        notification.should_receive(:unsubscribe)
        get :unsubscribe, valid_params.merge(format: 'json')
        response.should be_success
      end
    end

    describe "ignore" do
      it "should mark the notification as ignored" do
        notification.should_receive(:ignore)
        get :ignore, valid_params
        response.should be_redirect
      end

      it "should mark the notification as ignored via json" do
        notification.should_receive(:ignore)
        get :ignore, valid_params.merge(format: 'json')
        response.should be_success
      end
    end

    describe "cancel" do
      it "should mark the notification as cancelled" do
        notification.should_receive(:cancel)
        get :cancel, valid_params
        response.should be_redirect
      end

      it "should mark the notification as cancelled via json" do
        notification.should_receive(:cancel)
        get :cancel, valid_params.merge(format: 'json')
        response.should be_success
      end
    end
  end

  describe "when appending tracking params" do
    let(:target_url) { "http://example.com" }

    before(:each) do
      notification.email_urls = target_url
      controller.stub(:current_user).and_return(user)
      controller.stub(:notification).and_return(notification)
    end

    it "should set the utm source" do
      controller.stub(:utm_source).and_return("SOURCE")
      get :click, valid_params.merge(r: target_url)
      response.should redirect_to(target_url+"?utm_campaign=welcome&utm_medium=notification&utm_source=SOURCE")
    end

    it "should set the utm campaign" do
      notification.kind = "CAMPAIGN"
      get :click, valid_params.merge(r: target_url)
      response.should redirect_to(target_url+"?utm_campaign=CAMPAIGN&utm_medium=notification")
    end
  end
end

