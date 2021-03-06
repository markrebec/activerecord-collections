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

        def values_hash
          ActiveRecord::Collections::Serializer.to_hash(values.merge({collectable: klass}))
        end
        alias_method :to_values_hash, :values_hash

        def collection
          # do this with a hash so that we don't cause the relation query to execute
          c = kollektion.from_hash(values_hash)
          # TODO do we even need to do from_hash here? can we just create a new from_relation method instead that re-uses the same relation if we're already loaded?
          c.instance_variable_set(:@relation, self) if loaded?
          c
        end
        alias_method :to_collection, :collection
      end
    end
  end
end

ActiveRecord::Base.send :extend, ActiveRecord::Collections::Collectable::Model
ActiveRecord::Relation.send :include, ActiveRecord::Collections::Collectable::Relation
