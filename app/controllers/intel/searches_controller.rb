module Intel
  class SearchesController < ActionController::Base
    http_basic_authenticate_with name: ENV["INTEL_USERNAME"], password: ENV["INTEL_PASSWORD"] if ENV["INTEL_PASSWORD"]

    def index
      begin
        @searches_by_week = Intel::Search.group_by_week(:created_at, Time.zone, 12.weeks.ago.beginning_of_week(:sunday)..Time.now).count
        @no_results = Intel::Search.group(:query).where(results_count: 0).order("count_all desc").count
        @bad_conversion_rate = Intel::Search.connection.select_all("SELECT query, COUNT(*) as searches_count, COUNT(converted_at) as conversions_count, (100.0 * COUNT(converted_at) / COUNT(*)) as conversion_rate FROM searches GROUP BY query ORDER BY conversion_rate asc, searches_count desc, query asc LIMIT 10").select{|r| r["conversion_rate"].to_f < 50 }
      rescue ActiveRecord::StatementInvalid # TODO more selective rescue
        render text: "Be sure to run rails generate intel:install"
      end
    end

    def recent
      @searches = Intel::Search.order("created_at desc").limit(10)
    end
  end
end
