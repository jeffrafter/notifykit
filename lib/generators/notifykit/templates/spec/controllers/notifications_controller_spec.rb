# You can replace this with rails_helper for RSpec 3.0
require 'spec_helper'

<% if options.test_mode? %>
module RequireLogin
  def require_login
    redirect_to root_path unless current_user
  end
end

NotificationsController.send(:include, RequireLogin)
<% end %>

RSpec.describe NotificationsController, type: :controller do

  def login(user)
    allow(controller).to receive(:current_user).and_return(user)
  end

  def logout
    allow(controller).to receive(:current_user).and_return(nil)
  end

  let(:user) { create(:user) }
  let(:notification) { build(:notification, token: "TOKEN", user: user) }
  let(:valid_params) { { token: notification.token } }

  # Require login is assumed to be a method on your ApplicationController
  # it might have been created by Authkit.
  describe "requires login" do
    before(:each) do
      notification.save
    end

    it "redirects the if there is no user" do
      logout
      post :ignore, valid_params
      expect(response).to be_redirect
    end

    it "returns success if there is a user" do
      login(user)
      get :view, valid_params
      expect(response).to be_success
    end
  end

  describe "requires notification" do
    before(:each) do
      login(user)
    end

    it "raises a RecordNotFound if it can't find the notification" do
      expect {
        get :read, valid_params
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "doesn't find a notification belonging to another user" do
      expect {
        notification.user = create(:user)
        notification.save
        post :ignore, valid_params
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "returns success if there is a notification" do
      expect {
        notification.save
        get :view, valid_params
        expect(response).to be_success
      }.not_to raise_error
    end
  end

  describe "GET" do
    before(:each) do
      login(user)
      allow(controller).to receive(:notification).and_return(notification)
      allow(controller).to receive(:trackable).and_return(notification)
    end

    describe "recent" do
      it "should find recent notifications via json" do
        get :recent, { format: 'json' }
        expect(response).to be_success
      end
    end

    describe "view" do
      it "should view the html" do
        notification.email_html = "SOME HTML"
        get :view, valid_params
        expect(response).to be_success
        expect(response.body).to eq "SOME HTML"
      end

      it "should view the text" do
        notification.email_text = "SOME TEXT"
        get :view, valid_params.merge(format: 'text')
        expect(response).to be_success
        expect(response.body).to eq "SOME TEXT"
      end
    end

    describe "click" do
      it "should click and redirect" do
        target_url = "http://example.com"
        expect(notification).to receive(:click)
        notification.email_urls = target_url
        get :click, valid_params.merge(r: target_url)
        expect(response).to be_redirect
        expect(response).to redirect_to(target_url+"?utm_campaign=welcome&utm_medium=notification")
      end

      it "should not redirect to unknown urls" do
        target_url = "http://example.com"
        expect(notification).to receive(:click)
        get :click, valid_params.merge(r: target_url)
        expect(response).to be_redirect
        expect(response).to redirect_to(root_path+"?utm_campaign=welcome&utm_medium=notification")
      end

      it "should click via json" do
        expect(notification).to receive(:click)
        get :click, valid_params.merge(format: 'json')
        expect(response).to be_success
      end
    end

    describe "read" do
      it "should mark the notification as read" do
        expect(notification).to receive(:read)
        get :read, valid_params
        expect(response).to redirect_to(root_url)
      end
    end

    describe "unsubscribe" do
      it "should mark the notification as unsubscribed" do
        expect(notification).to receive(:unsubscribe)
        get :unsubscribe, valid_params
        expect(response).to be_redirect
      end

      it "should mark the notification as unsubscribed via json" do
        expect(notification).to receive(:unsubscribe)
        get :unsubscribe, valid_params.merge(format: 'json')
        expect(response).to be_success
      end
    end

    describe "ignore" do
      it "should mark the notification as ignored" do
        expect(notification).to receive(:ignore)
        get :ignore, valid_params
        expect(response).to be_redirect
      end

      it "should mark the notification as ignored via json" do
        expect(notification).to receive(:ignore)
        get :ignore, valid_params.merge(format: 'json')
        expect(response).to be_success
      end
    end

    describe "cancel" do
      it "should mark the notification as cancelled" do
        expect(notification).to receive(:cancel)
        get :cancel, valid_params
        expect(response).to be_redirect
      end

      it "should mark the notification as cancelled via json" do
        expect(notification).to receive(:cancel)
        get :cancel, valid_params.merge(format: 'json')
        expect(response).to be_success
      end
    end
  end

  describe "when appending tracking params" do
    let(:target_url) { "http://example.com" }

    before(:each) do
      login(user)
      notification.email_urls = target_url
      allow(controller).to receive(:trackable).and_return(notification)
    end

    it "should set the utm source" do
      allow(controller).to receive(:utm_source).and_return("SOURCE")
      get :click, valid_params.merge(r: target_url)
      expect(response).to redirect_to(target_url+"?utm_campaign=welcome&utm_medium=notification&utm_source=SOURCE")
    end

    it "should set the utm campaign" do
      notification.kind = "CAMPAIGN"
      get :click, valid_params.merge(r: target_url)
      expect(response).to redirect_to(target_url+"?utm_campaign=CAMPAIGN&utm_medium=notification")
    end
  end
end

