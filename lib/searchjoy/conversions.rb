# smart conversions reindexing
module Searchjoy
  # Smart reindexing with Searchkick the conversions Searchjoy tracks.
  #
  # ==== Attributes
  #
  # * +options+ - A Hash of options passed
  #
  # ==== Options
  #
  # * +:debug:+ - Turns on debugging to STDOUT can be :active_record, :searchkick or true for both
  # * +:callback:+ - A Symbol to override default of :bulk for Searchkick.callbacks
  # * +:batch_size:+ - An Integer to override batch_size in find_in_batches and searchkick model setting
  # * +:type:+ - A Class or String, or Array of both to only reindex those models
  # * +:from:+ - A DateTime object to reindex only from that point in time
  #
  # ==== Examples
  #
  #   Searchkick.reindex_conversions(from: 4.hours.ago)
  #
  def self.reindex_conversions(options = {})
    original_logger = {
      active_record: ActiveRecord::Base.logger,
      searchkick:    Searchkick::LogSubscriber.logger
    }

    debug_logger = Logger.new(STDOUT)

    if options[:debug]
      ActiveRecord::Base.logger = debug_logger        if [:active_record, true].include?(options[:debug])
      Searchkick::LogSubscriber.logger = debug_logger if [:searchkick,    true].include?(options[:debug])
    end

    if options[:type]
      options[:type] = Array[options[:type]] unless options[:type].is_a?(Array)
      options[:type] = options[:type].map(&:to_s) # coerce eventual classes to string
    end

    options[:callback] ||= :bulk
    stats_map = {}

    reindex_map(options) do |obj_map|
      obj_map.each do |klass_name, id_list|
        klass = klass_name.constantize
        options[:batch_size] ||= batch_size(klass)

        stats_map[klass_name] = 0 unless stats_map[klass_name]
        stats_map[klass_name] += id_list.count

        klass.where(id: id_list).find_in_batches(batch_size: options[:batch_size]) do |group|
          Searchkick.callbacks(options[:callback]) do
            group.each(&:reindex)
          end # Searchkick.callbacks
        end # klass.where
      end # obj_map.each
    end # reindex_map

    # reset logger back to original
    if options[:debug]
      ActiveRecord::Base.logger = original_logger[:active_record] if ActiveRecord::Base.logger == debug_logger
      Searchkick::LogSubscriber.logger = original_logger[:searchkick] if Searchkick::LogSubscriber.logger == debug_logger
    end

    # return statistics of { 'ModelName' => N_conversions }
    stats_map
  end # self.reindex_conversions

  # returns batch_size from model searchkick options or default to 1000
  #
  # ==== Attributes
  #
  # * +klass+ - A String containing model name or Class
  #
  # ==== Examples
  #
  #   batch_size(ModelName)
  #   batch_size('ModelName')
  #
  def self.batch_size(klass)
    klass = klass.constantize if klass.is_a?(String)
    num = nil
    num ||= klass.searchkick_options[:batch_size] if klass.respond_to?(:searchkick_options)
    num || 1_000
  end # def self.batch_size

  # return arel for column
  def self.arel(col)
    Searchjoy::Search.arel_table[col]
  end # self.arel

  # replaces writing SQL 'xxx IS NOT NULL'
  def self.not_null(col)
    arel(col).not_eq(nil)
  end # def self.not_null

  # Returns an Array of unique model names as strings from convertable_type
  def self.uniq_convertable_types(type = nil)
    query = Searchjoy::Search
            .select(:convertable_type).uniq
            .where(not_null(:convertable_type))
    query = query.where(convertable_type: type) if type
    query.pluck(:convertable_type)
  end # def self.uniq_convertable_types

  # Returns an ActiveRecord::Relation containing unique convertable_ids and id
  # for find_in_batches
  def self.uniq_convertable_ids(type)
    query = Searchjoy::Search
            .select(:convertable_id).uniq
            .select(:id)
            .where(not_null(:convertable_id))
            .where(convertable_type: type)
    query
  end # def self.uniq_convertable_ids

  # Fetches unique convertable_types and fetches unique convertable_ids by using
  # find_in_batches then yields a hash to block
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
end # module Searchjoy
