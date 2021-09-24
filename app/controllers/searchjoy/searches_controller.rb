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
      # determine period
      duration = @time_range.last - @time_range.first
      period =
        if duration < 3.days # shows 48-72 data points (ends at current time)
          "hour"
        elsif duration < 60.days
          "day"
        elsif duration < 60.weeks # to make it easy to compare to same time last year
          "week"
        else
          "month"
        end

      relation = Searchjoy::Search.where(search_type: params[:search_type])
      @searches_by_week = relation.group_by_period(period, :created_at, time_zone: @time_zone, range: @time_range).count
      @conversions_by_week = relation.where("converted_at is not null").group_by_period(period, :created_at, time_zone: @time_zone, range: @time_range).count
      @top_searches = @searches.first(5)
      @bad_conversion_rate = @searches.sort_by { |s| [s["conversion_rate"].to_f, s["query"]] }.first(5).select { |s| s["conversion_rate"] < 50 }
      @conversion_rate_by_week = {}
      @searches_by_week.each do |week, searches_count|
        @conversion_rate_by_week[week] = searches_count > 0 ? (100.0 * @conversions_by_week[week].to_f / searches_count).round : 0
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
      now = @time_zone.now
      start_at = Date.parse(params[:start_date]).in_time_zone(@time_zone) rescue (now - 12.weeks).in_time_zone(@time_zone).beginning_of_week(:sunday)
      end_at = Date.parse(params[:end_date]).in_time_zone(@time_zone).end_of_day rescue now
      start_at, end_at = end_at, start_at if start_at > end_at
      end_at = now if end_at > now
      @time_range = start_at..end_at

      # add time params if specified
      @time_params = {}
      @time_params[:start_date] = start_at.to_date if params[:start_date]
      @time_params[:end_date] = end_at.to_date if params[:end_date]
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
