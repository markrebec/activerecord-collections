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
          hash.symbolize_keys! unless hash.is_a?(HashWithIndifferentAccess)

          kollektion = kollektion_from_hash(hash)
          kollektable = kollektable_from_hash(hash)
          collection = kollektion.new(kollektable)
          collection.select!(*hash[:select]) unless hash[:select].empty?
          collection.distinct! if hash[:distinct] == true

          collection.joins!(*hash[:joins]) unless hash[:joins].empty?
          collection.references!(*hash[:references]) unless hash[:references].empty?
          collection.includes!(*hash[:includes]) unless hash[:includes].empty?

          wheres = hash[:where].partition { |w| w.is_a?(Hash) }
          wheres.first.each do |wh|
            if wh.keys.first == :not
              collection.not!(wh[:not])
            else
              collection.where!(wh)
            end
          end
          collection.where!(*hash[:bind].map { |b| b[:value] }.unshift(wheres.last.join(" AND ").gsub(/\$\d/,'?'))) unless wheres.last.empty?

          collection.group!(hash[:group]) unless hash[:group].empty?
          collection.order!(hash[:order]) unless hash[:order].empty?

          collection.limit!(hash[:limit]) unless hash[:limit].nil?
          collection.offset!(hash[:offset]) unless hash[:offset].nil?

          collection
        end

        def kollektion_from_hash(hash)
          kollektion = self
          kollektion = hash[:collection] if hash.has_key?(:collection) && !hash[:collection].nil?
          kollektion = kollektion.constantize unless kollektion.is_a?(Class)
          raise "Invalid collection class: #{kollektion}" unless kollektion <= ActiveRecord::Collection
          kollektion
        end

        def kollektable_from_hash(hash)
          kollektable = nil
          kollektable = hash[:collectable] if hash.has_key?(:collectable)
          kollektable = kollektable.constantize unless kollektable.is_a?(Class) || kollektable.nil?
          raise "Invalid collectable model: #{kollektable}" unless kollektable < ActiveRecord::Base
          kollektable
        end
      end

      def to_sql
        relation.to_sql
      end

      def to_hash(include_limit=false)
        values = relation.values.merge({collectable: collectable})
        values.merge!({limit: nil, offset: nil}) if !include_limit && !try(:is_batch?)
        values[:collection] = self.class if self.class < ActiveRecord::Collection
        ActiveRecord::Collections::Serializer.to_hash(values)
      end
      alias_method :to_h, :to_hash

      def as_json(options=nil)
        h = to_hash
        h[:collectable] = h[:collectable].try(:name)
        h[:collection] = h[:collection].name if h.has_key?(:collection)
        h.as_json(options)
      end

      def to_json(options=nil)
        as_json.to_json(options)
      end

      def to_param
        to_json
      end
    end
  end
end
