FactoryGirl.define do
  factory :retailer do
    name { Faker::Company.name }
  end
end
