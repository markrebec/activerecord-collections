FactoryGirl.define do
  factory :store_location do
    retailer
    address { [Faker::Address.street_address, Faker::Address.zip].join(" ") }
  end
end
