module Searchjoy
  # smart reindexing of conversions
  module Conversions
    def self.reindex(options = {})
      original_logger = {
        active_record: ActiveRecord::Base.logger,
        searchkick:    Searchkick::LogSubscriber.logger
      }

      debug_logger = Logger.new(STDOUT)

      if options[:debug]
        ActiveRecord::Base.logger = debug_logger        if [:active_record, true].include?(options[:debug])
        Searchkick::LogSubscriber.logger = debug_logger if [:searchkick, true].include?(options[:debug])
      end
      if options[:type]
        options[:type] = [options[:type]] unless options[:type].is_a?(Array)
        options[:type] = options[:type].map(&:to_s) # coerce eventual classes to string
      end

      options[:callback] ||= :bulk
      stats_map = {}

      reindex_map(options.select { |k, _v| [:type, :from, :batch_size].include?(k) }) do |obj_map|
        obj_map.each do |klass_name, id_list|
          klass = klass_name.constantize
          options[:batch_size] ||= batch_size(klass)

          stats_map[klass_name] = 0 unless stats_map[klass_name]
          stats_map[klass_name] += id_list.count

          klass.where(id: id_list).find_in_batches(batch_size: batch_size) do |group|
            Searchkick.callbacks(options[:callback]) do
              group.each(&:reindex)
            end
          end # klass.where
        end # obj_map
      end # reindex_hash.keys

      # reset logger back to original
      if options[:debug]
        ActiveRecord::Base.logger = original_logger[:active_record]     if ActiveRecord::Base.logger == debug_logger
        Searchkick::LogSubscriber.logger = original_logger[:searchkick] if Searchkick::LogSubscriber.logger == debug_logger
      end

      stats_map
    end # self.conversions

    def batch_size(klass)
      klass = klass.constantize if klass.is_a?(String)
      batch_size ||= klass.searchkick_options[:batch_size] if klass.respond_to?(:searchkick_options)
      batch_size || 1_000
    end

    def self.arel(col)
      Searchjoy::Search.arel_table[col]
    end

    def self.not_null(col)
      arel(col).not_eq(nil)
    end

    def self.uniq_convertable_types(type = nil)
      query = Searchjoy::Search
              .select(:convertable_type).uniq
              .where(not_null(:convertable_type))
      query = query.where(convertable_type: type) if type
      query.pluck(:convertable_type)
    end

    def self.uniq_convertable_ids(type)
      query = Searchjoy::Search
              .select(:convertable_id).uniq
              .select(:id)
              .where(not_null(:convertable_id))
              .where(convertable_type: type)
      query
    end

    def self.reindex_map(options = {})
      uniq_convertable_types(options[:type]).each do |convertable_type|
        ids_query = uniq_convertable_ids(convertable_type)
        ids_query = ids_query.where(arel(:created_at).gteq(options[:from])) if options[:from]

        ids_query.find_in_batches(batch_size: options[:batch_size] || batch_size(convertable_type)) do |group|
          reindex_ids = {}
          group.each do |conversion|
            reindex_ids[convertable_type] = [] unless reindex_ids[convertable_type]
            reindex_ids[convertable_type] << conversion.convertable_id.to_i
          end

          yield Hash[reindex_ids.map { |klass_name, id_list| [klass_name, id_list.sort.uniq] }]
        end # find_in_batches
      end # uniq_convertable_types.each
    end # def self.reindex_map
  end # module Conversions
end # module Searchjoy
