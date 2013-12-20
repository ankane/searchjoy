module Searchjoy
  class Search < ActiveRecord::Base
    belongs_to :convertable, polymorphic: true

    # the devise way
    if Rails::VERSION::MAJOR == 3 and !defined?(ActionController::StrongParameters)
      attr_accessible :search_type, :query, :results_count
    end

    before_save :set_normalized_query

    def convert(convertable = nil)
      if !converted?
        self.converted_at = Time.now
        self.convertable = convertable
        save(validate: false)
      end
    end

    def converted?
      converted_at.present?
    end

    protected

    def set_normalized_query
      self.normalized_query = query.downcase if query
    end

  end
end
