FactoryGirl.define do
  factory :message do
    from "test@example.com"
    category "newsletter"
    subject "An enticing subject"
    html_body "<p>Hi {{first_name}}</p>"
    text_body "Hi {{first_name}}"
  end
end

