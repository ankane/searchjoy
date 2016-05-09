module Searchjoy
  # smart reindexing of conversions
  module Conversions
    def self.reindex(options = {})
      return {} if conversions_objects.empty?

      batch_size = nil
      callback = :bulk

      options.keys.each do |key|
        case options[key]
        when :debug
          case options[:debug]
          when :active_record
            ActiveRecord::Base.logger = l
          when :searchkick
            Searchkick::LogSubscriber.logger = l if defined?(Searchkick)
          when true
            l = Logger.new(STDOUT)
            ActiveRecord::Base.logger = l
            Searchkick::LogSubscriber.logger = l if defined?(Searchkick)
          end
        when :batch_size
          batch_size = options[:batch_size]
        when :callback
          batch_size = options[:callback]
        end
      end

      reindex_map.keys.each do |klass_name|
        klass = klass_name.constantize

        batch_size ||= klass.searchkick_options[:batch_size] if klass.respond_to?(:searchkick_options)
        batch_size ||= 1_000

        Searchkick.callbacks(callback) do
          klass.where(id: reindex_map[klass_name]).find_in_batches(batch_size: batch_size) do |group|
            group.map(&:reindex)
          end
        end
      end # reindex_hash.keys

      # remap hash to show count of conversions id's for each key
      Hash[reindex_map.map { |klass_name, ids| [klass_name, ids.count] }]
    end # self.conversions

    def self.conversions_objects
      Searchjoy::Search.where('convertable_type IS NOT NULL').where('convertable_id IS NOT NULL').select(:convertable_id).uniq.select(:convertable_type)
    end

    def self.reindex_map
      reindex_ids = {}

      conversions_objects.each do |conversion|
        klass = conversion.convertable_type.to_s
        reindex_ids[klass] = [] unless reindex_ids[klass]
        reindex_ids[klass] << conversion.convertable_id.to_i
      end

      Hash[reindex_ids { |key, value| [key, value.sort.uniq] }]
    end
  end
end
