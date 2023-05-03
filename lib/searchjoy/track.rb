module Searchjoy
  module Track
    module Query
      def track
        results = @execute

        if options[:track] && !results.search
          attributes = options[:track] == true ? {} : options[:track]

          search_type =
            if klass.respond_to?(:name) && klass.name.present?
              klass.name
            elsif options[:models]
              Array(options[:models]).map(&:to_s).sort.join(" ")
            elsif options[:index_name]
              Array(options[:index_name]).map(&:to_s).sort.join(" ")
            else
              "All Indices"
            end

          results.search = create_search({search_type: search_type, query: term, results_count: results.total_count}.merge(attributes))
        end
      end
      
      # pull this out to allow override for multi_db support. ie:
      # module ReaderWrapper
      #   def create_search(hash)
      #     ActiveRecord::Base.connected_to(role: :writing) do
      #       super
      #     end
      #   end
      # end
      # Searchjoy::Track::Query.prepend(ReaderWrapper)
      def create_search(hash)
        Searchjoy::Search.create(hash)
      end

      def execute
        results = super
        track
        results
      end

      def search
        @execute.search if @execute
      end
    end

    module MultiSearch
      def perform
        result = super

        @queries.each do |query|
          query.track
        end

        result
      end
    end
  end
end
