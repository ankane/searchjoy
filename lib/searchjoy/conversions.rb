module Searchjoy
  # smart reindexing of conversions
  module Conversions
    def self.reindex(options = {})
      batch_size = nil
      type       = nil
      from       = nil
      callback   = :bulk
      original_logger = {
        active_record: ActiveRecord::Base.logger,
        searchkick:    Searchkick::LogSubscriber.logger
      }
      stats_map = {}

      debug_logger = Logger.new(STDOUT)

      options.keys.each do |key|
        case key
        when :debug
          case options[:debug]
          when :active_record
            ActiveRecord::Base.logger = debug_logger
          when :searchkick
            Searchkick::LogSubscriber.logger = debug_logger
          when true
            ActiveRecord::Base.logger = debug_logger
            Searchkick::LogSubscriber.logger = debug_logger
          end
        when :batch_size
          batch_size = options[:batch_size]
        when :callback
          callback = options[:callback]
        when :from
          from = options[:from]
        when :type
          type = options[:type]
          type = [type] unless type.is_a?(Array)
          type = type.map(&:to_s) # coerce eventual classes to string
        end
      end

      reindex_map(type, from) do |obj_map|
        obj_map.each do |klass_name, id_list|
          stats_map[klass_name] = 0 unless stats_map[klass_name]
          stats_map[klass_name] += id_list.count

          klass = klass_name.constantize
          batch_size ||= klass.searchkick_options[:batch_size] if klass.respond_to?(:searchkick_options)
          batch_size ||= 1_000

          klass.where(id: id_list).find_in_batches(batch_size: batch_size) do |group|
            Searchkick.callbacks(callback) do
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

    def self.reindex_map(type = nil, from = nil)
      query = Searchjoy::Search
              .select(:convertable_id).uniq
              .select(:convertable_type)
              .where('convertable_id IS NOT NULL')
              .where('convertable_type IS NOT NULL')

      query = query.where(convertable_type: type)  if type
      query = query.where('created_at >= ?', from) if from

      query.find_in_batches do |group|
        reindex_ids = {}
        group.each do |conversion|
          klass = conversion.convertable_type.to_s
          reindex_ids[klass] = [] unless reindex_ids[klass]
          reindex_ids[klass] << conversion.convertable_id.to_i
        end

        yield Hash[reindex_ids.map { |klass_name, id_list| [klass_name, id_list.sort.uniq] }]
      end
    end
  end
end
