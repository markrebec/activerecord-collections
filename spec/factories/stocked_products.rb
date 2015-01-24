FactoryGirl.define do
  factory :stocked_product do
    product
    retailer
    store_location
    stocked { (0..50).to_a.sample }
    cost { Faker::Commerce.price }
  end
end
