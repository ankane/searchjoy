require "bundler/setup"
require "combustion"
require "searchkick"
Bundler.require(:default)
require "minitest/autorun"
require "minitest/pride"

Combustion.path = "test/internal"
Combustion.initialize! :active_record, :action_controller

Product.reindex
Store.reindex
