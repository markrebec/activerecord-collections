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

  context 'batching' do
    describe 'default_batch_size' do
      it 'should default to 2000' do
        expect(ActiveRecord::Collection.default_batch_size).to eql(2000)
      end

      it 'should be overridable by extending classes' do
        expect(StockedProducts.default_batch_size).to eql(200)
      end
    end

    describe 'batching_threshold' do
      it 'should default to 10000' do
        expect(ActiveRecord::Collection.batching_threshold).to eql(10000)
      end

      it 'should be overridable by extending classes' do
        expect(StockedProducts.batching_threshold).to eql(500)
      end
    end
  end
end
