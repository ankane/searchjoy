module Searchjoy
  class SearchesController < ActionController::Base
    layout "searchjoy/application"

    http_basic_authenticate_with name: ENV["SEARCHJOY_USERNAME"], password: ENV["SEARCHJOY_PASSWORD"] if ENV["SEARCHJOY_PASSWORD"]

    before_filter :set_time_zone
    before_filter :set_search_types
    before_filter :set_search_type, only: [:index, :overview]
    before_filter :set_time_range, only: [:index, :overview]
    before_filter :set_searches, only: [:index, :overview]

    def index
      if params[:sort] == "conversion_rate"
        @searches.sort_by! { |s| [s["conversion_rate"].to_f, s["query"]] }
      end
    end

    def overview
      relation = Searchjoy::Search.where(search_type: params[:search_type])
      @searches_by_day = relation.group_by_day(:created_at, Time.zone, @time_range).count
      @conversions_by_day = relation.where("converted_at is not null").group_by_day(:created_at, Time.zone, @time_range).count
      @top_searches = @searches.first(5)
      @bad_conversion_rate = @searches.sort_by { |s| [s["conversion_rate"].to_f, s["query"]] }.first(5).select { |s| s["conversion_rate"] < 50 }
      @conversion_rate_by_day = {}
        @searches_by_day.each do |day, searches_count|
        @conversion_rate_by_day[day] = searches_count > 0 ? (100.0 * @conversions_by_day[day] / searches_count).round : 0
      end
    end

    def stream
    end

    def recent
      @searches = Searchjoy::Search.includes(:convertable).order("created_at desc").limit(50)
      render layout: false
    end

    protected

    def set_search_types
      @search_types = Searchjoy::Search.uniq.pluck(:search_type).sort
    end

    def set_search_type
      @search_type = params[:search_type].to_s
    end

    def set_time_zone
      @time_zone = Searchjoy.time_zone || Time.zone
    end

    def set_time_range
      if params[:daterange].present?
        from, to = params[:daterange].split(" - ")
        @time_range = Time.strptime(from, "%m/%d/%Y").in_time_zone(@time_zone)..Time.strptime(to, "%m/%d/%Y").in_time_zone(@time_zone)
      else
        @time_range = 8.days.ago.in_time_zone(@time_zone).beginning_of_day..Time.now
      end
    end

    def set_searches
      @limit = params[:limit] || Searchjoy.top_searches
      @searches = Searchjoy::Search.connection.select_all(Searchjoy::Search.select("normalized_query, COUNT(*) as searches_count, COUNT(converted_at) as conversions_count, AVG(results_count) as avg_results_count").where(created_at: @time_range, search_type: @search_type).group("normalized_query").order("searches_count desc, normalized_query asc").limit(@limit).to_sql).to_a
      @searches.each do |search|
        search["conversion_rate"] = 100 * search["conversions_count"].to_i / search["searches_count"].to_f
      end
    end
  end
end
