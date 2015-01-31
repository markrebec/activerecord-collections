module ActiveRecord
  module Collections
    module Delegation
      def self.included(base)
        base.send :extend, ClassMethods
      end

      module ClassMethods
        def method_missing(meth, *args)
          collection = new
          return collection.send(meth, *args) if collection.respond_to?(meth)
          super
        end
        
        def respond_to_missing?(meth, include_private=false)
          new.respond_to?(meth, include_private) || super
        end
      end

      def method_missing(meth, *args)
        if relation.respond_to?(meth)
          return call_on_relation(meth, *args)
        end

        if records_respond_to?(meth)
          return call_on_records(meth, *args)
        end

        super
      end

      def respond_to_missing?(meth, include_private=false)
        records_respond_to?(meth, include_private) ||
        relation.respond_to?(meth, include_private) ||
        super
      end

      def on_relation(&block)
        collection = dup
        collection.instance_eval do
          def self.method_missing(meth, *args)
            call_on_relation(meth, *args)
          end
          def self.respond_to_missing?(meth, include_private=false)
            relation.respond_to?(meth, include_private)
          end
        end
        return collection.instance_eval(&block) if block_given?
        collection
      end

      def on_records(&block)
        collection = dup
        collection.instance_eval do
          def self.method_missing(meth, *args)
            call_on_records(meth, *args)
          end
          def self.respond_to_missing?(meth, include_private=false)
            records_respond_to?(meth, include_private)
          end
        end
        return collection.instance_eval(&block) if block_given?
        collection
      end

      protected

      def call_on_records(meth, *args)
        return batch_map do |batch|
          if model.columns.map(&:name).include?(meth.to_s) && !batch.loaded?
            batch.pluck(meth)
          else
            batch.map { |record| record.send(meth, *args) }
          end
        end
      end

      def records_respond_to?(meth, include_private=false)
        model.public_instance_methods.include?(meth) ||
        (include_private && model.private_instance_methods.include?(meth)) ||
        (!records.nil? && records.loaded? && records.first.respond_to?(meth, include_private))
      end

      def call_on_relation(meth, *args)
        reset!(false, false)
        returned = relation.send(meth, *args)
        if returned.is_a?(ActiveRecord::Relation)
          @relation = returned
          self
        else
          returned
        end
      end
    end
  end
end
