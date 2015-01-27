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

      def to_a
        records.to_a
      end

      def total_records
        @total_records ||= relation.limit(nil).count
      end

      def total_count
        batch! if try(:should_batch?)
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
        batch! if try(:should_batch?)

        if try(:batched?)
          flat_batch_map.each { |record| block_given? ? yield(record) : record }
        else
          records.each { |record| block_given? ? yield(record) : record }
        end
      end

      def map(&block)
        batch! if try(:should_batch?)

        if try(:batched?)
          flat_batch_map.map { |record| block_given? ? yield(record) : record }
        else
          each.map { |record| block_given? ? yield(record) : record }
        end
      end

      def flat_map(&block)
        map(&block).flatten
      end
    end
  end
end
