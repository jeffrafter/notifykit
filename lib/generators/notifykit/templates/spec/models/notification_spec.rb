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
      Notification.recent.all.should == [notification]
    end

    it "does not find cancelled notifications" do
      notification.save
      create(:notification, cancelled_at: Time.now)
      Notification.recent.all.should == [notification]
    end
  end

  describe "validations" do
    it "validates email if delivering via email"
    it "validates email_subject if delivering via email"
  end

  it "should be clickable"
  it "should count the clicks"
  it "should be readable"
  it "should count the reads"
  it "should be ignorable"
  it "should be cancellable"
  it "should be cancelled"
  it "should be unsubscribable"

  describe "subject" do
    it "has a subject"
  end

  describe "delivering" do
    it "should deliver the notification"
    it "should not deliver if it has already been delivered"
    it "should not deliver unless it is delivering via email"
  end

  it "should set the email"
  it "should not set the email unless it is delivering via email"

  it "should set the token"
end
