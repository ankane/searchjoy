require_relative "test_helper"

require "rails/generators/test_case"
require "generators/searchjoy/install_generator"

class InstallGeneratorTest < Rails::Generators::TestCase
  tests Searchjoy::Generators::InstallGenerator
  destination File.expand_path("../tmp", __dir__)
  setup :prepare_destination

  def test_works
    run_generator
    assert_migration "db/migrate/install_searchjoy.rb", /:searchjoy_searches/
    assert_migration "db/migrate/install_searchjoy.rb", /:searchjoy_conversions/
  end
end
