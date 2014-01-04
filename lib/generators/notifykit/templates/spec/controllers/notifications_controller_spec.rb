require 'spec_helper'

describe NotificationsController do

  let(:user) { User.create(email: "test@example.com") }
  let(:notification) { build(:notification) }

  describe "requires login" do
  end

  describe "requires notification" do
  end

  describe "GET" do
    before(:each) do
      controller.stub(:require_login).and_return(true)
      controller.stub(:notification).and_return(notification)
    end

    describe "recent" do
    end

    describe "view" do
    end

    describe "click" do
    end

    describe "read" do
    end

    describe "unsubscribe" do
    end

    describe "ignore" do
    end

    describe "cancel" do
    end
  end

  describe "responding with no content" do
  end

  describe "when appending tracking params" do
  end
end

