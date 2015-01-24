require 'spec_helper'

RSpec.describe ActiveRecord::Collection do
  context 'querying' do
    before(:each) { create(:retailer) }

    it 'should return the same records as a standard relation' do
      retailer = Retailer.all.to_a.sample
      collection = StockedProducts.where(retailer_id: retailer.id)
      relation = StockedProduct.where(retailer_id: retailer.id)
      expect(collection.count).to eql(relation.count)
      expect(collection.pluck(:id).sort).to eql(relation.pluck(:id).sort)
    end
  end
end
