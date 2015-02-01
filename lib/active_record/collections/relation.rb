module ActiveRecord
  module Collections
    module Relation
      def self.included(base)
        base.send :extend, ClassMethods
      end

      module ClassMethods
        def select(*args)
          new.select(*args)
        end

        def distinct(bool=true)
          new.distinct(bool)
        end

        def where(*args, &block)
          new.where(*args, &block)
        end

        def order(*args, &block)
          new.order(*args, &block)
        end

        def limit(*args, &block)
          new.limit(*args, &block)
        end

        def joins(*args)
          new.joins(*args)
        end

        def includes(*args)
          new.includes(*args)
        end

        def references(*table_names)
          new.references(*table_names)
        end
      end

      def all
        reset
      end

      def load
        relation.load
        records
      end

      def select(*args)
        dup.select!(*args)
      end

      def select!(*args)
        @relation = relation.select(*args)
        self
      end

      def distinct(bool=true)
        dup.distinct!(bool)
      end

      def distinct!(bool=true)
        @relation = relation.distinct(bool)
        self
      end

      def where(*args, &block)
        dup.where!(*args, &block)
      end

      def where!(*args, &block)
        @relation = relation.where(*args, &block)
        self
      end

      def not(*args, &block)
        dup.not!(*args, &block)
      end

      def not!(*args, &block)
        @relation = relation.where.not(*args, &block)
        self
      end

      def or(*args, &block)
        dup.or!(*args, &block)
      end

      def or!(*args, &block)
        @relation = relation.or.where(*args, &block)
        self
      end

      def order(*args, &block)
        dup.order!(*args, &block)
      end

      def order!(*args, &block)
        relation.order!(*args, &block)
        self
      end

      def group(*args)
        dup.group!(*args)
      end

      def group!(*args)
        @relation = relation.group(*args)
        self
      end

      def limit(*args, &block)
        dup.limit!(*args, &block)
      end

      def limit!(*args, &block)
        @relation = relation.limit(*args, &block)
        self
      end

      def offset(*args, &block)
        dup.offset!(*args, &block)
      end

      def offset!(*args, &block)
        @relation = relation.offset(*args, &block)
        self
      end

      def joins(*args)
        dup.joins!(*args)
      end

      def joins!(*args)
        @relation = relation.joins(*args)
        self
      end

      def includes(*args)
        dup.includes!(*args)
      end

      def includes!(*args)
        @relation = relation.includes(*args)
        self
      end

      def references(*table_names)
        dup.references!(*table_names)
      end

      def references!(*table_names)
        @relation = relation.references(*table_names)
        self
      end

      %i(bind_values select_values distinct_value joins_values includes_values references_values where_values order_values limit_value offset_value).each do |meth|
        define_method meth do
          relation.send(meth)
        end
      end

      def reset(clear_total=true, clear_batches=true)
        dup.reset!(clear_total, clear_batches)
      end

      def reset!(clear_total=true, clear_batches=true)
        @records = @record_ids = @size = nil
        @total_count = nil if clear_total
        relation.reset
        if clear_batches
          @is_batched = false
          relation.limit!(nil).offset!(nil)
        end
        self
      end
    end
  end
end
