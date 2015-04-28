module ActiveRecord
  class Collection
    include ActiveRecord::Collections::Relation
    include ActiveRecord::Collections::Records
    include ActiveRecord::Collections::Batching
    include ActiveRecord::Collections::Delegation
    include ActiveRecord::Collections::Serialization
    include ActiveRecord::Collections::Pagination
    attr_reader :relation, :options

    COLLECTABLES = {}
    COLLECTIONS = []

    class << self
      def inherited(subclass)
        subclass.register!
      end

      def collections
        ActiveRecord::Collection::COLLECTIONS.map(&:constantize)
      end

      def register!
        register_collection
        register_collectable
      end

      def register_collection
        ActiveRecord::Collection::COLLECTIONS << name unless ActiveRecord::Collection::COLLECTIONS.include?(name)
      end

      def kollektable
        ActiveRecord::Collection::COLLECTABLES[name].try(:constantize)
      end

      def collectable=(klass)
        return if klass.nil?
        raise ArgumentError, "The collection model must inherit from ActiveRecord::Base" unless klass < ActiveRecord::Base
        ActiveRecord::Collection::COLLECTABLES[name] = klass.name
      end

      def register_collectable(klass=nil)
        if klass.nil?
          self.collectable = infer_collectable if kollektable.nil?
        else
          self.collectable = klass
        end
      end

      def collectable(klass=nil)
        register_collectable(klass)
        raise "Unable to determine a model to use for your collection, please set one with the `collectable` class method" if kollektable.nil?
        kollektable
      end
      alias_method :model, :collectable

      def infer_collectable
        singular = name.demodulize.singularize
        raise "Cannot infer collectable name from collection name" if singular == name.demodulize
        singular.constantize
      rescue
        parent = ancestors[1]
        return nil unless parent < ActiveRecord::Collection
        begin
          parent.collectable
        rescue
          nil
        end
      end
    end

    def collectable
      @collectable# ||= self.class.collectable
    end
    alias_method :model, :collectable

    # dup relation and call none so that we don't end up inspecting it
    # and loading it before we want it
    def inspect
      relation_backup = relation.dup
      @records = @relation = relation.none
      inspected = super
      @records = @relation = relation_backup
      inspected
    end

    protected

    def initialize(*criteria)
      criteria.compact!

      if criteria.first.present? && criteria.first.respond_to?(:ancestors) && criteria.first < ActiveRecord::Base
        @collectable = criteria.slice!(0)
      else
        @collectable = self.class.collectable
      end

      plural_name = collectable.name.demodulize.pluralize.underscore
      singular_name = collectable.name.demodulize.singularize.underscore

      self.class.instance_eval do
        alias_method plural_name.to_sym, :records
        alias_method "#{singular_name}_ids".to_sym, :record_ids
        alias_method "on_#{plural_name}".to_sym, :on_records
      end

      @options = {} # defaults, not implemented yet
      @options.merge!(criteria.extract_options!) if criteria.length > 1

      if criteria.length == 1
        criteria = criteria.first
        if criteria.is_a?(ActiveRecord::Relation)
          @relation = criteria
        elsif criteria.is_a?(Hash) || criteria.is_a?(String) || criteria.is_a?(Array)
          @relation = collectable.where(criteria).dup
        end
      else
        @relation = collectable.where(criteria).dup
      end
    end

    def initialize_copy(old)
      @collectable = old.collectable.name.constantize
      @options = old.options.dup
      @records = @relation = old.relation.dup
      @total_count = old.instance_variable_get(:@total_count)
      is_batch! if old.is_batch?
    end
  end
end
