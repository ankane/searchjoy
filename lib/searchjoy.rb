require "active_record"
require "chartkick"
require "groupdate"

require "searchjoy/track"
require "searchjoy/engine" if defined?(Rails)
require 'searchjoy/conversions' if defined?(Searchkick)
require "searchjoy/version"

module Searchjoy
  # time zone
  mattr_reader :time_zone
  def self.time_zone=(time_zone)
    @@time_zone = time_zone.is_a?(String) ? ActiveSupport::TimeZone.new(time_zone) : time_zone
  end

  # top searches
  mattr_accessor :top_searches
  self.top_searches = 100

  # conversion name
  mattr_accessor :conversion_name
  mattr_accessor :query_name
  mattr_accessor :query_url
end

begin
  require "searchkick"
rescue LoadError
  # do nothing
end

if defined?(Searchkick)
  module Searchkick
    class Query
      include Searchjoy::Track
      define_method(:execute_without_track, instance_method(:execute))
      define_method(:execute, instance_method(:execute_with_track))
    end

    class Results
      attr_accessor :search
    end
  end
end
