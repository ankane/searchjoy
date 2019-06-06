module Searchjoy
  class Search < ActiveRecord::Base
    self.table_name = "searchjoy_searches"

    belongs_to :convertable, polymorphic: true, optional: true
    belongs_to :user, optional: true

    before_save :set_normalized_query

    def convert(convertable = nil)
      unless converted?
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
