FactoryGirl.define do
  factory :retailer do
    name { Faker::Company.name }
    after(:create) do |retailer, evaluator|
      if Product.all.empty?
        20.times { create(:product) }
      end
      5.times do
        create(:store_location, retailer: retailer)
      end
    end
  end
end
