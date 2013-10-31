module Intel
  class Search < ActiveRecord::Base
    belongs_to :convertable, polymorphic: true

    def converted?
      converted_at.present?
    end
  end
end
