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
          kollektion.from_hash({
            collectable:  klass,
            select:       select_values,
            distinct:     distinct_value,
            joins:        joins_values,
            references:   references_values,
            includes:     includes_values,
            where:        where_values.map { |v| v.is_a?(String) ? v : v.to_sql },
            group:        group_values.map { |v| (v.is_a?(String) || v.is_a?(Symbol)) ? v : v.to_sql },
            order:        order_values.map { |v| (v.is_a?(String) || v.is_a?(Symbol)) ? v : v.to_sql },
            bind:         bind_values.map { |b| {name: b.first.name, value: b.last} },
            limit:        limit_value,
            offset:       offset_value
          })
        end
        alias_method :to_collection, :collection
      end
    end
  end
end

ActiveRecord::Base.send :extend, ActiveRecord::Collections::Collectable::Model
ActiveRecord::Relation.send :include, ActiveRecord::Collections::Collectable::Relation
