require "bundler/setup"
require "active_record"
require "searchkick"
Bundler.require(:default)
require "minitest/autorun"
require "minitest/pride"

ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"

if ENV["VERBOSE"]
  ActiveRecord::Base.logger = ActiveSupport::Logger.new(STDOUT)
end

ActiveRecord::Migration.create_table :products do |t|
  t.string :name
end

ActiveRecord::Migration.create_table :stores do |t|
  t.string :name
end

ActiveRecord::Migration.create_table :users do |t|
end

ActiveRecord::Migration.create_table :searchjoy_searches do |t|
  t.references :user
  t.string :search_type
  t.string :query
  t.string :normalized_query
  t.integer :results_count
  t.timestamp :created_at
  t.references :convertable, polymorphic: true, index: {name: "index_searchjoy_searches_on_convertable"}
  t.timestamp :converted_at
  t.string :source
end

class Product < ActiveRecord::Base
  searchkick
end

class Store < ActiveRecord::Base
  searchkick
end

class User < ActiveRecord::Base
end

Product.reindex
Store.reindex

require_relative "../app/models/searchjoy/search"
