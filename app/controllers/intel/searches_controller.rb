module Intel
  class SearchesController < ActionController::Base
    http_basic_authenticate_with name: ENV["INTEL_USERNAME"], password: ENV["INTEL_PASSWORD"] if ENV["INTEL_PASSWORD"]

    def index
      @searches_by_week = Intel::Search.group_by_week(:created_at, Time.zone, 12.weeks.ago.beginning_of_week(:sunday)..Time.now).count
    end

    def recent
      @searches = Intel::Search.order("created_at desc").limit(10)
    end
  end
end
