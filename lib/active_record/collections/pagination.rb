module ActiveRecord
  module Collections
    module Pagination
      def self.included(base)
        base.send :extend, ClassMethods
      end

      module ClassMethods
        def default_per_page(pp=nil)
          @default_per_page = pp unless pp.nil?
          @default_per_page ||= 25
        end
      end

      def default_per_page
        self.class.default_per_page
      end

      def page(pg=1)
        dup.page!(pg)
      end

      def page!(pg=1)
        paginate!(pg, default_per_page)
      end

      def per(pp=nil)
        dup.per!(pp)
      end

      def per!(pp=nil)
        paginate!(current_page, (pp || default_per_page))
      end

      def paginate!(pg, pp)
        limit!(pp.to_i)
        offset!((pg.to_i - 1) * pp.to_i)
      end

      def total_pages
        (total_count.to_f / (relation.limit_value || total_count).to_f).ceil
      end

      def current_page
        (relation.offset_value.to_i / (relation.limit_value || 1)) + 1
      end

      def per_page
        limit_value || total_count
      end

      def next_page
        current_page + 1 unless last_page?
      end

      def prev_page
        current_page - 1 unless first_page?
      end

      def next_page?
        !last_page?
      end

      def prev_page?
        !first_page?
      end

      def first_page?
        current_page == 1
      end

      def last_page?
        current_page == total_pages
      end

      def out_of_range?
        current_page > total_pages
      end
    end
  end
end
