class Retailer < ActiveRecord::Base
end

class StoreLocation < ActiveRecord::Base
  belongs_to :retailer
end

class Product < ActiveRecord::Base
end

class StockedProduct < ActiveRecord::Base
  belongs_to :product
  belongs_to :store_location
  belongs_to :retailer
end
