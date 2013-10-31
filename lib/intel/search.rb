module Intel
  class Search < ActiveRecord::Base
    belongs_to :convertable, polymorphic: true

    before_save :set_normalized_query

    def converted?
      converted_at.present?
    end

    protected

    def set_normalized_query
      self.normalized_query = query.downcase if query
    end

  end
end
