module Intel
  class SearchesController < ActionController::Base
    http_basic_authenticate_with name: ENV["INTEL_USERNAME"], password: ENV["INTEL_PASSWORD"] if ENV["INTEL_PASSWORD"]

    def index
      @time_range = 12.weeks.ago.beginning_of_week(:sunday)..Time.now
      @searches = Intel::Search.connection.select_all(Intel::Search.select("query, COUNT(*) as searches_count, COUNT(converted_at) as conversions_count").where(created_at: @time_range, search_type: params[:search_type]).group("query").order("searches_count desc, query asc").limit(200).to_sql).to_a
      @searches.each do |search|
        search["conversion_rate"] = 100 * search["conversions_count"].to_i / search["searches_count"].to_f
      end
      @searches.sort_by!{|s| s["conversion_rate"].to_f }
    end

    def overview
      begin
        @time_range = 12.weeks.ago.beginning_of_week(:sunday)..Time.now
        relation = Intel::Search.where(search_type: params[:search_type])
        @searches_by_week = relation.group_by_week(:created_at, Time.zone, @time_range).count
        @no_results = relation.group(:query).where(results_count: 0).where(created_at: @time_range).order("count_all desc").count
        @top_searches = relation.group(:query).order("count_all desc, query asc").limit(10).where(created_at: @time_range).count
        # TODO include search_type
        @bad_conversion_rate = Intel::Search.connection.select_all("SELECT query, COUNT(*) as searches_count, COUNT(converted_at) as conversions_count, (100.0 * COUNT(converted_at) / COUNT(*)) as conversion_rate FROM searches GROUP BY query ORDER BY conversion_rate asc, searches_count desc, query asc LIMIT 10").select{|r| r["conversion_rate"].to_f < 50 }
      rescue ActiveRecord::StatementInvalid # TODO more selective rescue
        render text: "Be sure to run rails generate intel:install"
      end
    end

    def stream
    end

    def recent
      @searches = Intel::Search.order("created_at desc").limit(10)
      # render json: Intel::Search.order("created_at desc").where("id > ?", params[:since_id]).as_json
    end
  end
end
