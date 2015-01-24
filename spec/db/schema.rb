ActiveRecord::Schema.define(:version => 0) do
  create_table :products do |t|
    t.string :brand
    t.string :name
  end

  create_table :retailers do |t|
    t.string :name
  end

  create_table :stocked_products do |t|
    t.integer :product_id
    t.integer :retailer_id
    t.integer :store_location_id
    t.integer :stocked
    t.float   :cost
  end

  create_table :store_locations do |t|
    t.integer :retailer_id
    t.string :address
  end
end
