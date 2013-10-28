module Intel
  class SearchesController < ActionController::Base
    layout "intel/application"

    http_basic_authenticate_with name: ENV["INTEL_USERNAME"], password: ENV["INTEL_PASSWORD"] if ENV["INTEL_PASSWORD"]

    before_filter :check_data, only: [:index, :overview, :stream]
    before_filter :set_time_range, only: [:index, :overview]
    before_filter :set_searches, only: [:index, :overview]

    def index
      if params[:sort] == "conversion_rate"
        @searches.sort_by!{|s| [s["conversion_rate"].to_f, s["query"]] }
      end
    end

    def overview
      @time_range = 12.weeks.ago.beginning_of_week(:sunday)..Time.now
      relation = Intel::Search.where(search_type: params[:search_type])
      @searches_by_week = relation.group_by_week(:created_at, Time.zone, @time_range).count
      @conversions_by_week = relation.where("converted_at is not null").group_by_week(:created_at, Time.zone, @time_range).count
      @top_searches = @searches.first(5)
      @bad_conversion_rate = @searches.sort_by{|s| [s["conversion_rate"].to_f, s["query"]] }.first(5).select{|s| s["conversion_rate"] < 50 }
      @conversion_rate_by_week = {}
      @searches_by_week.each do |week, searches_count|
        @conversion_rate_by_week[week] = searches_count > 0 ? (100.0 * @conversions_by_week[week] / searches_count).round : 0
      end
    end

    def stream
    end

    def recent
      @searches = Intel::Search.order("created_at desc").limit(10)
      render layout: false
    end

    protected

    def check_data
      begin
        if Intel::Search.count == 0
          @no_data = true
          render "no_data"
        end
      rescue ActiveRecord::StatementInvalid
        render text: "Be sure to run rails generate intel:install"
      end
    end

    def set_time_range
      @time_range = 12.weeks.ago.beginning_of_week(:sunday)..Time.now
    end

    def set_searches
      @limit = params[:limit] || 100
      @searches = Intel::Search.connection.select_all(Intel::Search.select("query, COUNT(*) as searches_count, COUNT(converted_at) as conversions_count, AVG(results_count) as avg_results_count").where(created_at: @time_range, search_type: params[:search_type]).group("query").order("searches_count desc, query asc").limit(@limit).to_sql).to_a
      @searches.each do |search|
        search["conversion_rate"] = 100 * search["conversions_count"].to_i / search["searches_count"].to_f
      end
    end
  end
end
