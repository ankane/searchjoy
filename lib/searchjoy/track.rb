module Searchjoy
  module Track
    def execute
      results = super

      if options[:track]
        attributes = options[:track] == true ? {} : options[:track]

        search_type =
          if klass.respond_to?(:name) && klass.name.present?
            klass.name
          elsif options[:index_name]
            Array(options[:index_name]).map(&:to_s).sort.join(" ")
          else
            "All Indices"
          end

        results.search = Searchjoy::Search.create({search_type: search_type, query: term, results_count: results.total_count}.merge(attributes))
      end

      results
    end
  end
end
