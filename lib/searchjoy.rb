# dependencies
require "active_support/core_ext/module/attribute_accessors"
require "chartkick"
require "groupdate"

# modules
require "searchjoy/track"
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

  # multiple conversions
  mattr_accessor :multiple_conversions
  self.multiple_conversions = false

  def self.attach_to_searchkick!
    Searchkick::Query.prepend(Searchjoy::Track::Query)
    Searchkick::MultiSearch.prepend(Searchjoy::Track::MultiSearch)
    Searchkick::Results.send(:attr_accessor, :search)
  end
end

if defined?(Rails)
  require "searchjoy/engine"
else
  Searchjoy.attach_to_searchkick! if defined?(Searchkick)
end
