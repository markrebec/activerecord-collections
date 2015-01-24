module ActiveRecord
  class Collection
    attr_reader :model, :relation, :options

    class << self
      def select(*args)
        new.select(*args)
      end

      def distinct(bool=true)
        new.distinct(bool)
      end

      def where(*args, &block)
        new.where(*args, &block)
      end

      def order(*args, &block)
        new.order(*args, &block)
      end

      def limit(*args, &block)
        new.limit(*args, &block)
      end

      def page(*num)
        new.page(*num)
      end
      alias_method :batch, :page

      def per(num)
        new.per(num)
      end
      alias_method :batch_size, :per

      def joins(*args)
        new.joins(*args)
      end

      def includes(*args)
        new.includes(*args)
      end

      def references(*table_names)
        new.references(*table_names)
      end

      def from_json(json)
        from_hash JSON.load(json)
      end

      def from_hash(hash)
        hash.symbolize_keys!
        set = new
        set.select!(*hash[:select]) unless hash[:select].empty?
        set.distinct! if hash[:distinct] == true
        set.joins!(*hash[:joins]) unless hash[:joins].empty?
        set.references!(*hash[:references]) unless hash[:references].empty?
        set.includes!(*hash[:includes]) unless hash[:includes].empty?
        set.where!(*hash[:bind].map { |b| b[:value] }.unshift(hash[:where].join(" AND ").gsub(/\$\d/,'?'))) unless hash[:where].empty?
        set.order!(hash[:order]) unless hash[:order].empty?
        set
      end
    end

    def on_relation(&block)
      set = dup
      set.instance_eval do
        def self.method_missing(meth, *args)
          return call_on_relation(meth, *args)
        end
      end
      return set.instance_eval(&block) if block_given?
      set
    end

    def on_results(&block)
      set = dup
      set.instance_eval do
        def self.method_missing(meth, *args)
          return call_on_results(meth, *args)
        end
      end
      return set.instance_eval(&block) if block_given?
      set
    end

    def method_missing(meth, *args)
      if relation.respond_to?(meth)
        return call_on_relation(meth, *args)
      end

      if model.public_instance_methods.include?(meth) || (!results.nil? && results.loaded? && results.first.respond_to?(meth))
        return call_on_results(meth, *args)
      end

      super
    end

    def respond_to_missing?(meth, include_private=false)
      model.public_instance_methods.include?(meth) ||
      (!results.nil? && results.loaded? && results.first.respond_to?(meth)) ||
      relation.respond_to?(meth) ||
      super
    end

    def results
      @results ||= relation
    end

    def result_ids
      @result_ids ||= results.loaded? ? results.map(&:id) : results.pluck(:id)
    end

    def to_a
      results.to_a
    end

    def length
      to_a.length
    end

    def total_count
      @total_count ||= relation.limit(nil).count
    end
    alias_method :total, :total_count
    alias_method :count, :total_count

    def paginated?
      !(@page.nil? && @per.nil?)
    end
    alias_method :batched?, :paginated?

    def current_page
      @page || 1
    end
    alias_method :current_batch, :current_page

    def per_page
      @per || total_count
    end
    alias_method :per_batch, :per_page

    def total_pages
      total_count / per_page
    end
    alias_method :total_batches, :total_pages

    def size
      relation.size
    end

    def all
      dup.reset.limit!(nil)
    end

    def each(&block)
      results.each { |result| yield result if block_given? }
    end

    def map(&block)
      each.map { |result| yield result if block_given? }
    end

    def flat_map(&block)
      map(&block).flatten
    end

    def each_page(&block)
      if total_pages <= 1
        yield results if block_given?
        return [results]
      end

      page!(1)
      paged = []
      while !results.empty? do
        paged << results
        yield results if block_given?
        next_page!
      end
      paged
    end
    alias_method :each_batch, :each_page

    def page_map(&block)
      if total_pages <= 1
        return (block_given? ? yield(results) : results)
      end

      page!(1)
      paged = []
      while !results.empty? do
        paged << (block_given? ? yield(results) : results)
        page!(current_page + 1)
      end
      paged
    end
    alias_method :batch_map, :page_map

    def flat_page_map(&block)
      page_map(&block).flatten
    end
    alias_method :flat_batch_map, :flat_page_map

    def first_page
      dup.first_page!
    end
    alias_method :first_batch, :first_page

    def first_page!
      page!(1)
    end
    alias_method :first_batch!, :first_page!

    def next_page?
      current_page < total_pages
    end
    alias_method :next_batch?, :next_page?

    def next_page
      dup.next_page!
    end
    alias_method :next_batch, :next_page

    def next_page!
      page!(current_page + 1) if next_page?
    end
    alias_method :next_batch!, :next_page!

    def prev_page?
      current_page > 1
    end
    alias_method :prev_batch?, :prev_page?

    def prev_page
      dup.prev_page!
    end
    alias_method :prev_batch, :prev_page

    def prev_page!
      page!(current_page - 1) if prev_page?
    end
    alias_method :prev_batch!, :prev_page!

    def last_page
      dup.last_page!
    end
    alias_method :last_batch, :last_page

    def last_page!
      page!(total_pages)
    end
    alias_method :last_batch!, :last_page!

    def load
      relation.load
      results
    end

    def select(*args)
      dup.select!(*args)
    end

    def select!(*args)
      @results = nil
      @result_ids = nil
      @total_count = nil
      @relation = relation.reset.select(*args)
      self
    end

    def distinct(bool=true)
      dup.distinct!(bool)
    end

    def distinct!(bool=true)
      @results = nil
      @result_ids = nil
      @total_count = nil
      @relation = relation.reset.distinct(bool)
      self
    end

    def where(*args, &block)
      dup.where!(*args, &block)
    end

    def where!(*args, &block)
      @results = nil
      @result_ids = nil
      @total_count = nil
      relation.reset.where!(*args, &block)
      self
    end

    def not(*args, &block)
      dup.not!(*args, &block)
    end

    def not!(*args, &block)
      @relation = relation.reset.where.not(*args, &block)
      self
    end

    def or(*args, &block)
      dup.or!(*args, &block)
    end

    def or!(*args, &block)
      @relation = relation.reset.or.where(*args, &block)
      self
    end

    def order(*args, &block)
      dup.order!(*args, &block)
    end

    def order!(*args, &block)
      @results = nil
      @result_ids = nil
      relation.reset.order!(*args, &block)
      self
    end

    def limit(*args, &block)
      dup.limit!(*args, &block)
    end

    def limit!(*args, &block)
      @results = nil
      @result_ids = nil
      relation.reset.limit!(*args, &block)
      self
    end

    def page(*num)
      dup.page!(*num)
    end
    alias_method :batch, :page

    def page!(*num)
      @results = nil
      @result_ids = nil
      @page = num[0] || 1
      @per ||= 25
      @relation = relation.page(@page).per(@per)
      self
    end
    alias_method :batch!, :page!

    def per(num=nil)
      dup.per!(num)
    end
    alias_method :batch_size, :per

    def per!(num)
      @results = nil
      @result_ids = nil
      @page ||= 1
      @per = num
      @relation = relation.page(@page).per(@per)
      self
    end
    alias_method :batch_size!, :per!

    def joins(*args)
      dup.joins!(*args)
    end

    def joins!(*args)
      @results = nil
      @result_ids = nil
      relation.joins!(*args)
      self
    end

    def includes(*args)
      dup.includes!(*args)
    end

    def includes!(*args)
      @results = nil
      @result_ids = nil
      relation.includes!(*args)
      self
    end

    def references(*table_names)
      dup.references!(*table_names)
    end

    def references!(*table_names)
      @results = nil
      @result_ids = nil
      relation.references!(*table_names)
      self
    end

    # dup relation and call none so that we don't end up inspecting it
    # and loading it before we want it
    def inspect
      relation_backup = relation.dup
      @results = @relation = relation.none
      inspected = super
      @results = @relation = relation_backup
      inspected
    end

    def to_sql
      all.relation.to_sql
    end

    def to_hash
      {
        select:     relation.select_values,
        distinct:   relation.distinct_value,
        joins:      relation.joins_values,
        references: relation.references_values,
        includes:   relation.includes_values,
        where:      relation.where_values.map { |v| v.is_a?(String) ? v : v.to_sql },
        order:      relation.order_values.map { |v| v.is_a?(String) ? v : v.to_sql },
        bind:       relation.bind_values.map { |b| {name: b.first.name, value: b.last} }
      }
    end
    alias_method :to_h, :to_hash

    def to_json(options=nil)
      to_hash.to_json
    end

    def to_param
      to_json
    end

    def reset
      @page = @per = @results = @result_ids = @total_count = nil
      relation.reset
      self
    end

    protected

    def initialize(model, *criteria)
      @model = model
      self.class.instance_eval do
        alias_method model.name.demodulize.pluralize.underscore.to_sym, :results
      end
      @options = {} # defaults
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
      @results = @relation = old.relation.dup
      page!(old.current_page).per!(old.per_page) if old.paginated?
    end

    def call_on_results(meth, *args)
      return page_map do |batch|
        if model.columns.map(&:name).include?(meth.to_s) && !batch.loaded?
          batch.pluck(meth)
        else
          batch.map { |result| result.send(meth, *args) }
        end
      end
    end

    def call_on_relation(meth, *args)
      @results = nil
      @result_ids = nil
      @total_count = nil
      @relation = relation.reset.send(meth, *args)
      return self
    end
  end
end
