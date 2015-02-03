module ActiveRecord
  module Collections
    module Collectable
      module Model
        def collection_class(klass=nil)
          @collection_class = klass unless klass.nil?
          @collection_class
        end
        alias_method :collector, :collection_class

        def kollektion
          plural_klass = begin
            pklass = self.name.pluralize.constantize
            raise "Not an ActiveRecord::Collection" unless pklass.ancestors.include?(ActiveRecord::Collection)
            pklass
          rescue
            nil
          end
          @collection_class || ActiveRecord::Collection.collections.to_a.select { |c| c.collectable == self }.first || plural_klass || ActiveRecord::Collection
        end

        def collection(*criteria)
          kollektion.new(self, *criteria)
        end
        alias_method :to_collection, :collection
      end

      module Relation
        def kollektion
          klass.kollektion
        end

        def collection
          # do this with a hash so that we don't cause the relation query to execute
          hash = ActiveRecord::Collections::Serializer.to_hash(values.merge({collectable: klass}))
          kollektion.from_hash(hash)
        end
        alias_method :to_collection, :collection
      end
    end
  end
end

ActiveRecord::Base.send :extend, ActiveRecord::Collections::Collectable::Model
ActiveRecord::Relation.send :include, ActiveRecord::Collections::Collectable::Relation
