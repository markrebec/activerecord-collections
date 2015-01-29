module ActiveRecord
  class Collection
    include ActiveRecord::Collections::Relation
    include ActiveRecord::Collections::Records
    include ActiveRecord::Collections::Batching
    include ActiveRecord::Collections::Delegation
    include ActiveRecord::Collections::Serialization
    attr_reader :model, :relation, :options

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

    def initialize(model, *criteria)
      @model = model
      self.class.instance_eval do
        model_plural = model.name.demodulize.pluralize.underscore
        model_singular = model.name.demodulize.singularize.underscore
        alias_method model_plural.to_sym, :records
        alias_method "#{model_singular}_ids".to_sym, :record_ids
        alias_method "on_#{model_plural}".to_sym, :on_records
      end
      @options = {} # defaults, not implemented yet
      @options.merge!(criteria.extract_options!) if criteria.length > 1

      if criteria.length == 1
        criteria = criteria.first
        if criteria.is_a?(ActiveRecord::Relation)
          @relation = criteria
        elsif criteria.is_a?(Hash) || criteria.is_a?(String) || criteria.is_a?(Array)
          @relation = model.where(criteria).dup
        end
      else
        @relation = model.where(criteria).dup
      end
    end

    def initialize_copy(old)
      @options = old.options.dup
      @records = @relation = old.relation.dup
      @total_records = old.total_records if !old.is_batch? && old.instance_variable_get(:@total_records).to_i > 0
      page!(old.current_page).per!(old.per_page) if old.is_batch? || old.batched?(false)
      is_batch! if old.is_batch?
    end
  end
end
