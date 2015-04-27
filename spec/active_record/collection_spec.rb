require 'spec_helper'

RSpec.describe ActiveRecord::Collection do
  context 'when querying' do
    before(:each) { 5.times { create(:retailer) } }

    it 'returns the same records as a standard relation' do
      retailer = Retailer.all.to_a.sample
      collection = StockedProducts.where(retailer_id: retailer.id)
      relation = StockedProduct.where(retailer_id: retailer.id)
      expect(collection.count).to eql(relation.count)
      expect(collection.pluck(:id).sort).to eql(relation.pluck(:id).sort)
    end

    describe 'not' do
      it 'excludes records matching the criteria' do
      retailer = Retailer.all.to_a.sample
      collection = StockedProducts.not(retailer_id: retailer.id)
      relation = StockedProduct.where.not(retailer_id: retailer.id)
      expect(collection.count).to eql(relation.count)
      expect(collection.pluck(:id).sort).to eql(relation.pluck(:id).sort)
      end
    end

    describe 'to_collection' do
      it 'reproduces the same result set' do
        retailer = Retailer.all.to_a.sample
        product = retailer.stocked_products.sample.product
        relation = StockedProduct.where.not(retailer_id: retailer.id, product_id: product.id)
        collection = StockedProduct.where.not(retailer_id: retailer.id, product_id: product.id).to_collection
        expect(collection.count).to eql(relation.count)
        expect(collection.pluck(:id).sort).to eql(relation.pluck(:id).sort)
      end
    end
  end

  context 'when batching' do
    describe 'default_batch_size' do
      it 'defaults to 500' do
        expect(ActiveRecord::Collection.default_batch_size).to eql(500)
      end

      it 'is overridable by extending classes' do
        expect(StockedProducts.default_batch_size).to eql(200)
      end
    end

    describe 'batching_threshold' do
      it 'defaults to 0' do
        expect(ActiveRecord::Collection.batching_threshold).to eql(0)
      end

      it 'is overridable by extending classes' do
        expect(StockedProducts.batching_threshold).to eql(500)
      end
    end
  end
end
