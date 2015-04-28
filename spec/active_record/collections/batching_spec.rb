require 'spec_helper'

RSpec.describe ActiveRecord::Collection do
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
