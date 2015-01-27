module ActiveRecord
  module Collections
    module QueryChain
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
        reset.limit!(nil)
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

      def reset(clear_total=true, clear_pages=true)
        dup.reset!(clear_total, clear_pages)
      end

      def reset!(clear_total=true, clear_pages=true)
        @records = @record_ids = nil
        @page = @per = nil if clear_pages
        @total_count = nil if clear_total
        relation.reset
        self
      end
    end
  end
end
