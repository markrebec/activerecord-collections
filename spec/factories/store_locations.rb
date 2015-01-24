FactoryGirl.define do
  factory :store_location do
    retailer
    address { [Faker::Address.street_address, Faker::Address.zip].join(" ") }
    after(:create) do |location, evaluator|
      products = Product.all
      if products.empty?
        20.times do
          create(:stocked_product, store_location: location, retailer: location.retailer)
        end
      else
        products.each do |product|
          create(:stocked_product, store_location: location, retailer: location.retailer, product: product)
        end
      end
    end
  end
end
