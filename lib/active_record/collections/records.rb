module ActiveRecord
  module Collections
    module Records
      def records
        @records ||= relation
      end

      def record_ids
        @record_ids ||= records.loaded? ? records.map(&:id) : records.pluck(:id)
      end

      def to_a
        records.to_a
      end

      def total_count
        @total_count ||= relation.limit(nil).count
      end
      alias_method :total, :total_count
      alias_method :count, :total_count

      def size
        relation.size
      end

      def length
        to_a.length
      end

      def each(&block)
        records.each { |record| yield record if block_given? }
      end

      def map(&block)
        each.map { |record| yield record if block_given? }
      end

      def flat_map(&block)
        map(&block).flatten
      end
    end
  end
end
