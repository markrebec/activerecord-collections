module ActiveRecord
  module Collections
    module Collectable
      module Model
        def collection(*criteria)
          ActiveRecord::Collection.new(self, *criteria)
        end
        alias_method :collect, :collection
      end

      module Relation
        def collection
          ActiveRecord::Collection.from_hash({
            klass:      klass,
            select:     select_values,
            distinct:   distinct_value,
            joins:      joins_values,
            references: references_values,
            includes:   includes_values,
            where:      where_values.map { |v| v.is_a?(String) ? v : v.to_sql },
            order:      order_values.map { |v| v.is_a?(String) ? v : v.to_sql },
            bind:       bind_values.map { |b| {name: b.first.name, value: b.last} },
            limit:      limit_value,
            offset:     offset_value
          })
        end
        alias_method :collect, :collection
      end
    end
  end
end

ActiveRecord::Base.send :extend, ActiveRecord::Collections::Collectable::Model
ActiveRecord::Relation.send :include, ActiveRecord::Collections::Collectable::Relation
