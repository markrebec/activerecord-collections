require 'spec_helper'

RSpec.describe ActiveRecord::Collection do
  context 'querying' do
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
        relation = StockedProduct.where.not(retailer_id: retailer.id)
        collection = StockedProduct.where.not(retailer_id: retailer.id).to_collection
        expect(collection.count).to eql(relation.count)
        expect(collection.pluck(:id).sort).to eql(relation.pluck(:id).sort)
      end

      it 'supports multiple parameters' do
        retailer = Retailer.all.to_a.sample
        product = retailer.stocked_products.sample.product
        relation = StockedProduct.where.not(retailer_id: retailer.id, product_id: product.id)
        collection = StockedProduct.where.not(retailer_id: retailer.id, product_id: product.id).to_collection
        expect(collection.count).to eql(relation.count)
        expect(collection.pluck(:id).sort).to eql(relation.pluck(:id).sort)
      end
    end
  end

  context 'subclassing' do
    it 'infers the collectable from the class name' do
      expect(Retailers.collectable).to eql(Retailer)
    end

    it 'allows setting a collectable' do
      expect(ProductCollection.collectable).to eql(Product)
    end

    context 'multiple collections for the same model' do
      it 'registers all of them as collections for the model' do
        expect(ActiveRecord::Collection::COLLECTABLES[StockedProducts.name]).to eql('StockedProduct')
        expect(ActiveRecord::Collection::COLLECTABLES[StockedProductCollection.name]).to eql('StockedProduct')
      end
    end

    context 'a subclass' do
      it 'registers itself as a collection' do
        expect(ActiveRecord::Collection.collections).to include(ProductCollection)
        expect(ActiveRecord::Collection.collections).to include(AnotherProductCollection)
      end

      it 'inherits the parent collectable' do
        expect(AnotherProductCollection.collectable).to eql(Product)
        expect(MoreRetailers.collectable).to eql(Retailer)
      end
    end
  end
end
