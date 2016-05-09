module Searchjoy
  module Track
    def search_with_track(term, options = {}, &block)
      results = search_without_track(term, options) do |body|
        block.call(body) if block
      end

      if options[:track]
        attributes = options[:track] == true ? {} : options[:track]
        results.search = Searchjoy::Search.create({ search_type: name, query: term, results_count: results.total_count }.merge(attributes))
      end
      results
    end
  end
end
