require "active_record"
require "chartkick"
require "groupdate"

require "searchjoy/track"
require "searchjoy/engine" if defined?(Rails)
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
end

begin
  require "searchkick"
rescue LoadError
  # do nothing
end

if defined?(Searchkick)
  module Searchkick
    module Reindex
      def self.extended(base)
        base.send(:extend, Searchjoy::Track)
        method_name = Searchkick.respond_to?(:search_method_name) ? Searchkick.search_method_name : :search
        base.define_singleton_method(:search_without_track, base.method(method_name))
        base.define_singleton_method(method_name, base.method(:search_with_track))
      end
    end

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
