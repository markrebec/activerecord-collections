module ActiveRecord
  module Collections
    module Batching
      def self.included(base)
        base.send :extend, ClassMethods
      end

      module ClassMethods
        def default_batch_size(size=nil)
          @default_batch_size = size unless size.nil?
          @default_batch_size ||= 2_000
        end

        def batching_threshold(threshold=nil)
          @batching_threshold = threshold unless threshold.nil?
          @batching_threshold ||= 10_000
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

      def should_batch?(check_if_batched=true)
        return false if is_batch?
        return false if check_if_batched && batched?
        batch_by_default?
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
          batches << batched.next_batch!.as_batch
        end
        batches
      end

      def as_batches(&block)
        total_count # init count once before duping
        batched = dup.batch!
        batches = [batched.first_batch!.as_batch]
        yield batches.first if block_given?
        while batched.next_batch? do
          b = batched.next_batch!.as_batch
          yield b if block_given?
          batches << b
        end
        batches
      end
      alias_method :in_batches, :as_batches

      def batch(batch: 1, batch_size: nil)
        dup.batch!(batch: batch, batch_size: batch_size)
      end

      def batch!(batch: 1, batch_size: nil)
        reset!(false, false)
        @current_batch = batch
        @batch_size = batch_size unless batch_size.nil?
        @batch_size ||= default_batch_size
        @relation = relation.limit(@batch_size).offset((@current_batch - 1) * @batch_size)
        self
      end

      def per_batch(num=nil)
        dup.per_batch!(num)
      end

      def per_batch!(num=nil)
        reset!(false, false)
        @current_batch ||= 1
        @batch_size = num || default_batch_size
        @relation = relation.limit(@batch_size).offset((@current_batch - 1) * @batch_size)
        self
      end

      def batched?(check_if_should=false)
        return true if !(@current_batch.nil? && @batch_size.nil?)
        if check_if_should && should_batch?(false)
          batch!
          true
        else
          false
        end
      end

      def current_batch
        @current_batch || 1
      end

      def batch_size
        @batch_size || total_count
      end

      def total_batches
        return 1 if is_batch?
        (total_count.to_f / batch_size.to_f).ceil
      end

      def each_batch(&block)
        batch! if should_batch?

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
        batch! if should_batch?

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
        batch!(batch: 1)
      end

      def next_batch?
        current_batch < total_batches
      end

      def next_batch
        dup.next_batch!
      end

      def next_batch!
        batch!(batch: current_batch + 1) if next_batch?
      end

      def prev_batch?
        current_batch > 1
      end

      def prev_batch
        dup.prev_batch!
      end

      def prev_batch!
        batch!(batch: current_batch - 1) if prev_batch?
      end

      def last_batch
        dup.last_batch!
      end

      def last_batch!
        batch!(batch: total_batches)
      end
    end
  end
end
