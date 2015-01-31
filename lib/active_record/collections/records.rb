module ActiveRecord
  module Collections
    module Records
      def records
        @records ||= relation
      end

      def record_ids
        @record_ids ||= records.loaded? ? records.map(&:id) : records.pluck(:id)
      end

      def pluck(col)
        relation.pluck(col)
      end

      def to_ary
        records.to_a
      end
      alias_method :to_a, :to_ary

      def total_records
        @total_records ||= relation.limit(nil).count
      end

      def total_count
        total_records
      end
      alias_method :total, :total_count
      alias_method :count, :total_count

      def size
        @size ||= relation.size
      end

      def length
        to_a.length
      end

      def each(&block)
        records.each { |record| block_given? ? yield(record) : record }
      end

      def each_in_batches(batch_size=nil, &block)
        batch_size!(batch_size)
        flat_batch_map.each { |record| block_given? ? yield(record) : record }
      end

      def map(&block)
        each.map { |record| block_given? ? yield(record) : record }
      end

      def map_in_batches(batch_size=nil, &block)
        batch_size!(batch_size)
        flat_batch_map.map { |record| block_given? ? yield(record) : record }
      end

      def flat_map(&block)
        map(&block).flatten
      end

      def flat_map_in_batches(batch_size=nil, &block)
        batch_size!(batch_size)
        flat_batch_map.map { |record| block_given? ? yield(record) : record }
      end
    end
  end
end
