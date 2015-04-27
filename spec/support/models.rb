class Retailer < ActiveRecord::Base
  has_many :stocked_products
end

class StoreLocation < ActiveRecord::Base
  belongs_to :retailer
  has_many :stocked_products
end

class Product < ActiveRecord::Base
  has_many :stocked_products
end

class StockedProduct < ActiveRecord::Base
  belongs_to :product
  belongs_to :store_location
  belongs_to :retailer
end

class StockedProducts < ActiveRecord::Collection
  default_batch_size 200
  batching_threshold 500
end

class StockedProductCollection < ActiveRecord::Collection
  collectable StockedProduct
end

class ProductCollection < ActiveRecord::Collection
  collectable Product
end

class AnotherProductCollection < ProductCollection
end

class Retailers < ActiveRecord::Collection
end

class MoreRetailers < Retailers
end
