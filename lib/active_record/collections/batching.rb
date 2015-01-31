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

        def page(*num)
          new.page(*num)
        end
        alias_method :batch, :page

        def per(num)
          new.per(num)
        end
        alias_method :per_batch, :per
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
          total_records >= batching_threshold )
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
        next_page!.as_batch
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

      # TODO Mark need to either depend on kaminari or check for it before using page/per
      def page(*num)
        dup.page!(*num)
      end
      alias_method :batch, :page

      def page!(*num)
        reset!(false, false)
        @page = num[0] || 1
        @per ||= default_batch_size
        @relation = relation.page(@page).per(@per)
        self
      end
      alias_method :batch!, :page!

      def per(num=nil)
        dup.per!(num)
      end
      alias_method :per_batch, :per

      def per!(num)
        reset!(false, false)
        @page ||= 1
        @per = num
        @relation = relation.page(@page).per(@per)
        self
      end
      alias_method :per_batch!, :per!

      def paginated?(check_if_should=false)
        return true if !(@page.nil? && @per.nil?)
        if check_if_should && should_batch?(false)
          batch!
          true
        else
          false
        end
      end
      alias_method :batched?, :paginated?

      def current_page
        @page || 1
      end
      alias_method :current_batch, :current_page

      def page_size
        @per || total_count
      end
      alias_method :batch_size, :page_size

      def total_pages
        return 1 if is_batch?
        (total_count.to_f / page_size.to_f).ceil
      end
      alias_method :total_batches, :total_pages

      def each_page(&block)
        batch! if should_batch?

        if total_pages <= 1
          yield to_a if block_given?
          return [to_a]
        end

        first_page!
        paged = []
        total_pages.times do
          paged << to_a
          yield to_a if block_given?
          next_page!
        end
        first_page!
        paged
      end
      alias_method :each_batch, :each_page

      def page_map(&block)
        batch! if should_batch?

        if total_pages <= 1
          return (block_given? ? yield(to_a) : to_a)
        end

        first_page!
        paged = []
        total_pages.times do
          paged << (block_given? ? yield(to_a) : to_a)
          next_page!
        end
        first_page!
        paged
      end
      alias_method :batch_map, :page_map

      def flat_page_map(&block)
        page_map(&block).flatten
      end
      alias_method :flat_batch_map, :flat_page_map

      def first_page
        dup.first_page!
      end
      alias_method :first_batch, :first_page

      def first_page!
        page!(1)
      end
      alias_method :first_batch!, :first_page!

      def next_page?
        current_page < total_pages
      end
      alias_method :next_batch?, :next_page?

      def next_page
        dup.next_page!
      end
      alias_method :next_batch, :next_page

      def next_page!
        page!(current_page + 1) if next_page?
      end
      alias_method :next_batch!, :next_page!

      def prev_page?
        current_page > 1
      end
      alias_method :prev_batch?, :prev_page?

      def prev_page
        dup.prev_page!
      end
      alias_method :prev_batch, :prev_page

      def prev_page!
        page!(current_page - 1) if prev_page?
      end
      alias_method :prev_batch!, :prev_page!

      def last_page
        dup.last_page!
      end
      alias_method :last_batch, :last_page

      def last_page!
        page!(total_pages)
      end
      alias_method :last_batch!, :last_page!
    end
  end
end
