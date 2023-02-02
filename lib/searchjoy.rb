# dependencies
require "active_support/core_ext/module/attribute_accessors"
require "chartkick"
require "groupdate"

# modules
require_relative "searchjoy/track"
require_relative "searchjoy/version"

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
  self.multiple_conversions = true

  def self.attach_to_searchkick!
    Searchkick::Query.prepend(Searchjoy::Track::Query)
    Searchkick::MultiSearch.prepend(Searchjoy::Track::MultiSearch)
    Searchkick::Results.send(:attr_accessor, :search)
  end

  def self.backfill_conversions
    Searchjoy::Search.where.not(converted_at: nil).left_joins(:conversions).where(searchjoy_conversions: {id: nil}).find_in_batches do |searches|
      conversions =
        searches.map do |search|
          {
            search_id: search.id,
            convertable_id: search.convertable_id,
            convertable_type: search.convertable_type,
            created_at: search.converted_at
          }
        end
      if ActiveRecord::VERSION::MAJOR >= 6
        Searchjoy::Conversion.insert_all(conversions)
      else
        Searchjoy::Conversion.transaction do
          Searchjoy::Conversion.create!(conversions)
        end
      end
    end
  end
end

if defined?(Rails)
  require_relative "searchjoy/engine"
else
  Searchjoy.attach_to_searchkick! if defined?(Searchkick)
end
