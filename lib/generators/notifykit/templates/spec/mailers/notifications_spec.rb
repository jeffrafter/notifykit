require "spec_helper"

describe Notifications do
  describe "notify" do
    let(:mail) { Notifications.notify }

    it "renders the headers" do
      mail.subject.should eq("Notify")
      mail.to.should eq(["to@example.org"])
      mail.from.should eq(["from@example.com"])
    end

    it "renders the body" do
      mail.body.encoded.should match("Hi")
    end
  end

end
