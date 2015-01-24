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
  protected

  def initialize(*criteria)
    super(StockedProduct, *criteria)
  end
end
