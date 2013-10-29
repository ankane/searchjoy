module Intel
  class Search < ActiveRecord::Base
    self.table_name = "searches"

    belongs_to :convertable, polymorphic: true

    def converted?
      converted_at.present?
    end
  end
end
