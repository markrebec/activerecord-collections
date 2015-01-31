module ActiveRecord
  module Collections
    module ModelCollection
      def self.included(base)
        base.send :extend, ClassMethods
      end

      module ClassMethods
        def collection(*criteria)
          ActiveRecord::Collection.new(self, *criteria)
        end
        alias_method :collect, :collection
      end
    end
  end
end

ActiveRecord::Base.send :include, ActiveRecord::Collections::ModelCollection
