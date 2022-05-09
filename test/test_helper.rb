require "bundler/setup"
require "combustion"
require "searchkick"
Bundler.require(:default)
require "minitest/autorun"
require "minitest/pride"

logger = ActiveSupport::Logger.new(ENV["VERBOSE"] ? STDOUT : nil)

Combustion.path = "test/internal"
Combustion.initialize! :active_record, :action_controller do
  config.active_record.logger = logger
end

Product.reindex
Store.reindex
