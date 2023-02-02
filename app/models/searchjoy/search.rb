module Searchjoy
  class Search < ActiveRecord::Base
    self.table_name = "searchjoy_searches"

    belongs_to :convertable, polymorphic: true, optional: true
    belongs_to :user, optional: true
    has_many :conversions

    before_validation :truncate_query
    before_save :set_normalized_query

    def convert(convertable = nil)
      return unless Searchjoy.multiple_conversions || !converted?

      # use transaction to keep consistent
      self.class.transaction do
        # make time consistent
        now = Time.now

        if Searchjoy.multiple_conversions
          conversion =
            conversions.create!(
              convertable: convertable,
              created_at: now
            )
        end

        unless converted?
          self.converted_at = now
          # check id instead of association
          self.convertable = convertable if respond_to?(:convertable_id=)
          save(validate: false)
        end

        conversion
      end
    end

    def converted?
      converted_at.present?
    end

    protected

    def truncate_query
      return unless ( max_length = self.class.type_for_attribute(:query).limit ).present?
      self.query = query.truncate( max_length )
    end

    def set_normalized_query
      self.normalized_query = query.downcase if query
    end
  end
end
