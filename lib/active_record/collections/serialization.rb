module ActiveRecord
  module Collections
    module Serialization
      def self.included(base)
        base.send :extend, ClassMethods
      end

      module ClassMethods
        def from_json(json)
          from_hash JSON.load(json)
        end

        def from_hash(hash)
          hash.symbolize_keys!
          collection = new(hash[:klass])
          collection.select!(*hash[:select]) unless hash[:select].empty?
          collection.distinct! if hash[:distinct] == true
          collection.joins!(*hash[:joins]) unless hash[:joins].empty?
          collection.references!(*hash[:references]) unless hash[:references].empty?
          collection.includes!(*hash[:includes]) unless hash[:includes].empty?
          collection.where!(*hash[:bind].map { |b| b[:value] }.unshift(hash[:where].join(" AND ").gsub(/\$\d/,'?'))) unless hash[:where].empty?
          collection.group!(hash[:group]) unless hash[:group].empty?
          collection.order!(hash[:order]) unless hash[:order].empty?
          collection.limit!(hash[:limit]) unless hash[:limit].nil?
          collection.offset!(hash[:offset]) unless hash[:offset].nil?
          collection
        end
      end

      def to_sql
        relation.to_sql
      end

      def to_hash(include_limit=false)
        h = {
          select:     select_values,
          distinct:   distinct_value,
          joins:      joins_values,
          references: references_values,
          includes:   includes_values,
          where:      where_values.map { |v| v.is_a?(String) ? v : v.to_sql },
          group:      group_values.map { |v| (v.is_a?(String) || v.is_a?(Symbol)) ? v : v.to_sql },
          order:      order_values.map { |v| (v.is_a?(String) || v.is_a?(Symbol)) ? v : v.to_sql },
          bind:       bind_values.map { |b| {name: b.first.name, value: b.last} }
        }
        if include_limit || try(:is_batch?)
          h[:limit] = limit_value
          h[:offset] = offset_value
        end
        h
      end
      alias_method :to_h, :to_hash

      def to_json(options=nil)
        to_hash.to_json
      end

      def to_param
        to_json
      end
    end
  end
end
