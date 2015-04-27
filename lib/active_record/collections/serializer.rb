module ActiveRecord
  module Collections
    class Serializer
      attr_reader :values

      def self.to_hash(*args)
        new(*args).to_hash
      end

      def collectable
        values[:collectable]
      end

      def collection
        values[:collection]
      end

      def select
        values[:select]
      end

      def distinct
        values[:distinct]
      end

      def joins
        values[:joins]
      end

      def includes
        values[:includes]
      end

      def references
        values[:references]
      end

      def group
        values[:group].map { |v| (v.is_a?(String) || v.is_a?(Symbol)) ? v : v.to_sql }
      end

      def order
        values[:order].map { |v| (v.is_a?(String) || v.is_a?(Symbol)) ? v : v.to_sql }
      end

      def limit
        values[:limit]
      end

      def offset
        values[:offset]
      end

      def bind
        @bind ||= values[:bind].map { |b| {name: b.first.name.to_s, value: b.last} }
      end

      def where
        return @where unless @where.nil?

        @where = values[:where].map { |node| serialize_node(node) }
        hashed = {}
        @where.select! do |w|
          if w.is_a?(Hash)
            if hashed.has_key?(w.keys.first)
              hashed[w.keys.first].merge!(w.values.first)
            else
              hashed[w.keys.first] = w.values.first
            end
            false
          else
            true
          end
        end
        @where.unshift(hashed)
        @where
      end

      def to_hash
        {
          collectable: collectable,
          collection: collection,
          select: select,
          distinct: distinct,
          joins: joins,
          includes: includes,
          references: references,
          where: where,
          bind: bind,
          group: group,
          order: order,
          limit: limit,
          offset: offset
        }
      end

      protected

      def initialize(*args)
        @values = {
          collectable: nil,
          collection: nil,
          where: [],
          bind: [],
          select: [],
          distinct: nil,
          group: [],
          order: [],
          joins: [],
          includes: [],
          references: [],
          limit: nil,
          offset: nil
        }.merge(args.extract_options!)
      end

      def serialize_node(node)
        if node.is_a?(String)
          node
        elsif node.class < Arel::Nodes::Node
          case node
          when Arel::Nodes::Grouping
            serialize_node(node.expr)
          when Arel::Nodes::And
            node.children.map { |child| serialize_node(child) }
          when Arel::Nodes::NotEqual
            bound = bind.delete_at(bind.find_index { |b| b[:name] == node.left.name.to_s })[:value]
            {not: {node.left.name.to_sym => bound}}
          when Arel::Nodes::Or
            {or: [serialize_node(node.left), serialize_node(node.right)]}
          else
            if node.right.is_a?(Arel::Nodes::BindParam)
              bound = bind.delete_at(bind.find_index { |b| b[:name] == node.left.name.to_s })[:value]
            elsif node.right.is_a?(Arel::Nodes::Casted)
              bound = node.right.val
            elsif node.right.is_a?(Array)
              bound = node.right.map do |n|
                raise "ActiveRecord::Collection does not know how to serialize this attribute: #{node.left.name} / #{n.class.name}" unless n.is_a?(Arel::Nodes::Casted)
                n.val
              end
            else
              raise "ActiveRecord::Collection does not know how to serialize this attribute: #{node.left.name} / #{node.right.class.name}"
            end
            {node.left.relation.name.to_s => {node.left.name.to_s => bound}}
          end
        end
      end
    end
  end
end
