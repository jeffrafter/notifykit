require "spec_helper"

describe Message do
  let(:message) { create(:message) }
  let(:user) { create(:user) }

  before(:each) do
    Rails.application.default_url_options[:host] = "http://example.com"
  end

  # This spec is pending until you put in the default address
  it "has a default from address"

  describe "delivering" do
    it "uses the default from address if the from address is blank" do
      expect_any_instance_of(Mail::Message).to receive(:deliver)
      default_from = "boss@hogg.com"
      expect(Message).to receive(:default_from).and_return(default_from)
      message.from = nil
      result = message.deliver(user)
      expect(result.email_from).to eq(default_from)
    end

    it "does not deliver duplicates" do
      message.deliver(user)
      expect_any_instance_of(Mail::Message).to_not receive(:deliver)
      result = message.deliver(user)
      expect(result).to be_nil
     end

    it "delivers duplicates if forced" do
      message.deliver(user)
      expect_any_instance_of(Mail::Message).to receive(:deliver)
      result = message.deliver(user, true)
      expect(result).to_not be_nil
    end

    it "creates a notification" do
      expect {
        message.deliver(user)
      }.to change(Notification, :count)
    end

    it "delivers the notification" do
      expect_any_instance_of(Notification).to receive(:deliver)
      message.deliver(user)
    end

    it "delivers to all" do
      3.times { |i| create(:user, email: "deliver-all-test-#{i}@example.com") }
      expect(message).to receive(:deliver).exactly(3).times
      message.deliver_to_all
    end
  end

  it "knows if it has been delivered" do
    message.deliver(user)
    expect(message.send(:delivered_to?, user)).to eq(true)
  end

  describe "formatting" do
    it "formats html" do
      user.first_name = "Trucker"
      expect(message.formatted_html_body(user)).to eq("<p>Hi Trucker</p>")
    end

    it "formats text" do
      user.first_name = "Trucker"
      expect(message.formatted_text_body(user)).to eq("Hi Trucker")
    end
  end

  describe "preprocessing" do
    it "preprocesses the content" do
      user.first_name = "Trucker"
      user.last_name = "Baxter"
      allow(user).to receive(:full_name).and_return("Trucker Baxter")
      expect(message.send(:preprocess, "Hi {{first_name}}", user)).to eq("Hi Trucker")
      expect(message.send(:preprocess, "Hi {{last_name}}", user)).to eq("Hi Baxter")
      expect(message.send(:preprocess, "Hi {{full_name}}", user)).to eq("Hi Trucker Baxter")
    end
  end
end
