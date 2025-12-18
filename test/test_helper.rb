require "bundler/setup"
require "combustion"
require "searchkick"
Bundler.require(:default)
require "minitest/autorun"

logger = ActiveSupport::Logger.new(ENV["VERBOSE"] ? STDOUT : nil)

Combustion.path = "test/internal"
Combustion.initialize! :active_record, :action_controller do
  config.load_defaults Rails::VERSION::STRING.to_f
  config.active_record.logger = logger
end

Searchkick.index_prefix = "searchjoy"

Product.reindex
Store.reindex

class Minitest::Test
  def with_options(name, value)
    previous_value = Searchjoy.send(name)
    begin
      Searchjoy.send("#{name}=", value)
      yield
    ensure
      Searchjoy.send("#{name}=", previous_value)
    end
  end
end
