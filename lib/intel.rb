require "searchkick"
require "intel/search"
require "intel/track"
require "intel/engine"
require "intel/version"

module Searchkick
  module Search
    include Intel::Track

    alias_method :search_without_track, :search
    alias_method :search, :search_with_track
  end
end
