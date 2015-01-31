module ActiveRecord
  module Collections
    module Batching
      def self.included(base)
        base.send :extend, ClassMethods
      end

      module ClassMethods
        def default_batch_size(size=nil)
          @default_batch_size = size unless size.nil?
          @default_batch_size ||= 500
        end

        def batching_threshold(threshold=nil)
          @batching_threshold = threshold unless threshold.nil?
          @batching_threshold ||= 0
        end

        def batch_by_default!
          @batch_by_default = true
        end

        def batch_by_default?
          @batch_by_default || false
        end

        def batch(*num)
          new.batch(*num)
        end

        def batch_size(num)
          new.batch_size(num)
        end
      end

      def default_batch_size
        self.class.default_batch_size
      end

      def batching_threshold
        self.class.batching_threshold
      end

      def batch_by_default?
        self.class.batch_by_default? ||
        ( batching_threshold > 0 &&
          total_count >= batching_threshold )
      end

      def should_batch?
        return false if is_batch?
        batch_by_default?
      end

      def is_batched?
        @is_batched || false
      end
      alias_method :batched?, :is_batched?

      def batch(btch=1)
        dup.batch!(btch)
      end

      def batch!(btch=1)
        batchify!(btch, default_batch_size)
      end

      def per_batch(bs=nil)
        dup.per_batch!(bs)
      end

      def per_batch!(bs=nil)
        batchify!(current_batch, (bs || default_batch_size))
      end

      def batchify!(btch, bs)
        @is_batched = true
        limit!(bs.to_i)
        offset!((btch.to_i - 1) * bs.to_i)
      end

      def total_batches
        (total_count.to_f / (relation.limit_value || total_count).to_f).ceil
      end

      def current_batch
        (relation.offset_value.to_i / (relation.limit_value || 1)) + 1
      end

      def batch_size
        limit_value || total_count
      end

      def is_batch!
        @is_batch = true
        self
      end

      def is_batch?
        @is_batch || false
      end
      alias_method :batch?, :is_batch?

      def as_batch
        dup.is_batch!
      end

      def as_next_batch
        next_batch!.as_batch
      end

      def to_batches
        total_count # init count once before duping
        batched = dup.batch!
        batches = [batched.first_batch!.as_batch]
        while batched.next_batch? do
          batches << batched.as_next_batch
        end
        batches
      end

      def as_batches(&block)
        total_count # init count once before duping
        batched = dup.batch!
        batches = [batched.first_batch!.as_batch]
        yield batches.first if block_given?
        while batched.next_batch? do
          b = batched.as_next_batch
          yield b if block_given?
          batches << b
        end
        batches
      end
      alias_method :in_batches, :as_batches

      def each_batch(&block)
        batch!

        if total_batches <= 1
          yield to_a if block_given?
          return [to_a]
        end

        first_batch!
        batched = []
        total_batches.times do
          batched << to_a
          yield to_a if block_given?
          next_batch!
        end
        first_batch!
        batched
      end

      def batch_map(&block)
        batch!

        if total_batches <= 1
          return (block_given? ? yield(to_a) : to_a)
        end

        first_batch!
        batched = []
        total_batches.times do
          batched << (block_given? ? yield(to_a) : to_a)
          next_batch!
        end
        first_batch!
        batched
      end

      def flat_batch_map(&block)
        batch_map(&block).flatten
      end

      def first_batch
        dup.first_batch!
      end

      def first_batch!
        batch!(1)
      end

      def next_batch?
        current_batch < total_batches
      end

      def next_batch
        dup.next_batch!
      end

      def next_batch!
        batch!(current_batch + 1) if next_batch?
      end

      def prev_batch?
        current_batch > 1
      end

      def prev_batch
        dup.prev_batch!
      end

      def prev_batch!
        batch!(current_batch - 1) if prev_batch?
      end

      def last_batch
        dup.last_batch!
      end

      def last_batch!
        batch!(total_batches)
      end
    end
  end
end
