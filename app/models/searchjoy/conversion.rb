module Searchjoy
  class Conversion < ActiveRecord::Base
    self.table_name = "searchjoy_conversions"

    belongs_to :search
    belongs_to :convertable, polymorphic: true, optional: true
  end
end
