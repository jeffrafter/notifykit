require "spec_helper"

describe Notifications do
  describe "notify" do
    let(:notification) { create(:notification) }
    let(:mail) { Notifications.notify(notification.id) }

    it "renders the headers" do
    end

    it "renders the body" do
    end
  end

end
