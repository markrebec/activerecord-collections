module ActiveRecord
  class Collection
    include ActiveRecord::Collections::Relation
    include ActiveRecord::Collections::Records
    include ActiveRecord::Collections::Batching
    include ActiveRecord::Collections::Delegation
    include ActiveRecord::Collections::Serialization
    include ActiveRecord::Collections::Pagination
    attr_reader :relation, :options

    class << self
      def collectable(klass=nil)
        unless klass.nil?
          raise ArgumentError, "The collection model must inherit from ActiveRecord::Base" unless klass.ancestors.include?(ActiveRecord::Base)
          @collectable = klass
        end

        if @collectable.nil?
          begin
            klass = self.name.demodulize.singularize.constantize
            @collectable = klass if !klass.nil? && klass.ancestors.include?(ActiveRecord::Base)
          rescue
            # singularized class doesn't exist
          end
        end

        raise "Unable to determine a model to use for your collection, please set one with the `collectable` class method" if @collectable.nil? # TODO implement real exceptions
        @collectable
      end
      alias_method :model, :collectable
    end

    def collectable
      @collectable ||= self.class.collectable
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
      if criteria.first.present? && criteria.first.ancestors.include?(ActiveRecord::Base)
        @collectable = criteria.slice!(0)
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
      @collectable = old.collectable
      @options = old.options.dup
      @records = @relation = old.relation.dup
      @total_count = old.instance_variable_get(:@total_count)
      batch!(batch: old.current_batch, batch_size: old.batch_size) if old.is_batch? || old.batched?(false)
      is_batch! if old.is_batch?
    end
  end
end
