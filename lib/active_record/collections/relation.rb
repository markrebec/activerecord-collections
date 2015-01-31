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
        reset!
        @relation = relation.select(*args)
        self
      end

      def distinct(bool=true)
        dup.distinct!(bool)
      end

      def distinct!(bool=true)
        reset!
        @relation = relation.distinct(bool)
        self
      end

      def where(*args, &block)
        dup.where!(*args, &block)
      end

      def where!(*args, &block)
        reset!
        relation.where!(*args, &block)
        self
      end

      def not(*args, &block)
        dup.not!(*args, &block)
      end

      def not!(*args, &block)
        reset!
        @relation = relation.where.not(*args, &block)
        self
      end

      def or(*args, &block)
        dup.or!(*args, &block)
      end

      def or!(*args, &block)
        reset!
        @relation = relation.or.where(*args, &block)
        self
      end

      def order(*args, &block)
        dup.order!(*args, &block)
      end

      def order!(*args, &block)
        reset!(false)
        relation.order!(*args, &block)
        self
      end

      def limit(*args, &block)
        dup.limit!(*args, &block)
      end

      def limit!(*args, &block)
        reset!
        relation.limit!(*args, &block)
        self
      end

      def offset(*args, &block)
        dup.offset!(*args, &block)
      end

      def offset!(*args, &block)
        reset!
        relation.offset!(*args, &block)
        self
      end

      # TODO make this not dependent on kaminari
      def page!(*args)
        @relation = relation.page(*args)
        self
      end
      alias_method :page, :page!

      def per!(*args)
        @relation = relation.page((relation.offset_value / relation.limit_value) + 1).per(*args)
        self
      end
      alias_method :per, :per!
      # END kaminari

      def joins(*args)
        dup.joins!(*args)
      end

      def joins!(*args)
        reset!
        relation.joins!(*args)
        self
      end

      def includes(*args)
        dup.includes!(*args)
      end

      def includes!(*args)
        reset!
        relation.includes!(*args)
        self
      end

      def references(*table_names)
        dup.references!(*table_names)
      end

      def references!(*table_names)
        reset!
        relation.references!(*table_names)
        self
      end

      def reset(clear_total=true, clear_batches=true)
        dup.reset!(clear_total, clear_batches)
      end

      def reset!(clear_total=true, clear_batches=true)
        @records = @record_ids = @size = nil
        @total_records = nil if clear_total
        relation.reset
        if clear_batches
          @current_batch = @batch_size = nil
          relation.limit!(nil).offset!(nil)
        end
        self
      end
    end
  end
end
