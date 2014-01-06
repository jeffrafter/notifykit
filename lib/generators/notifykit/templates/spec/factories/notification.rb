FactoryGirl.define do
  factory :notification do
    category "confirmation"
    kind "welcome"
    email "test@example.com"
    email_subject "This is a sample notification"
    email_from "sender@example.com"
  end
end

