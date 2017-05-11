module Searchjoy
  class SearchesController < ActionController::Base
    protect_from_forgery with: :exception

    layout "searchjoy/application"

    http_basic_authenticate_with name: ENV["SEARCHJOY_USERNAME"], password: ENV["SEARCHJOY_PASSWORD"] if ENV["SEARCHJOY_PASSWORD"]

    before_action :set_time_zone
    before_action :set_search_types
    before_action :set_search_type, only: [:index, :overview]
    before_action :set_time_range, only: [:index, :overview]
    before_action :set_searches, only: [:index, :overview]

    def index
      if params[:sort] == "conversion_rate"
        @searches.sort_by! { |s| [s["conversion_rate"].to_f, s["query"]] }
      end
    end

    def overview
      relation = Searchjoy::Search.where(search_type: params[:search_type])
      @searches_by_week = relation.group_by_week(:created_at, Time.zone, @time_range).count
      @conversions_by_week = relation.where("converted_at is not null").group_by_week(:created_at, Time.zone, @time_range).count
      @top_searches = @searches.first(5)
      @bad_conversion_rate = @searches.sort_by { |s| [s["conversion_rate"].to_f, s["query"]] }.first(5).select { |s| s["conversion_rate"] < 50 }
      @conversion_rate_by_week = {}
      @searches_by_week.each do |week, searches_count|
        @conversion_rate_by_week[week] = searches_count > 0 ? (100.0 * @conversions_by_week[week] / searches_count).round : 0
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
      @search_types = Searchjoy::Search.distinct.pluck(:search_type).sort
    end

    def set_search_type
      @search_type = params[:search_type].to_s
    end

    def set_time_zone
      @time_zone = Searchjoy.time_zone || Time.zone
    end

    def set_time_range
      @time_range = 8.weeks.ago.in_time_zone(@time_zone).beginning_of_week(:sunday)..Time.now
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
