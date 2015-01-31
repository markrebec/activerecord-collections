module ActiveRecord
  module Collections
    module Pagination
      def page(*args)
        dup.page!(*args)
      end

      def page!(*args)
        @relation = relation.page(*args)
        self
      end

      def per(*args)
        dup.per!(*args)
      end

      def per!(*args)
        @relation = relation.page(current_page).per(*args)
        self
      end

      def total_pages
        (total_count.to_f / (relation.limit_value || total_count).to_f).ceil
      end

      def current_page
        (relation.offset_value.to_i / (relation.limit_value || 1)) + 1
      end

      def per_page
        limit_value
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
