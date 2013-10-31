require "intel/search"
require "intel/track"
require "intel/engine"
require "intel/version"

require "chartkick"
require "groupdate"

module Intel
  # time zone
  mattr_reader :time_zone
  def self.time_zone=(time_zone)
    @@time_zone = time_zone.is_a?(String) ? ActiveSupport::TimeZone.new(time_zone) : time_zone
  end

  # top count
  mattr_accessor :top_count
  self.top_count = 100
end

if defined?(Searchkick)
  module Searchkick
    module Search
      include Intel::Track

      alias_method :search_without_track, :search
      alias_method :search, :search_with_track
    end

    class Results
      attr_accessor :search
    end
  end
end
