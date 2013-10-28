module Intel
  class Search < ActiveRecord::Base
    self.table_name = "searches"

    belongs_to :convertable, polymorphic: true
  end
end
